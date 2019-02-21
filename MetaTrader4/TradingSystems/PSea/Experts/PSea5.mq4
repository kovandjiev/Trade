//+------------------------------------------------------------------+
//|                                                      PSea3_1.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Add hashing
// Add if signal for close order arrived, close these orders type. Result is the same as PSea3
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "1.00"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int SignalId = 7; // Open signal system Id form 1 to 8
extern int CloseSignalId = 2; // Close signal system 1 to 3
extern double Lot = 0.01; // Open order Lot
//extern int Stoploss = 25; // Stop loss in pips
//extern bool DynamicStopLoss = true; // Using dynamic Stop loss
//extern int DynamicSLExtraPoints = 0; // Dynamic Stop loss extra points 0 to 50
extern double DynCloseCoeff = 0.07; // Dynamic close order coefficient 0.01 to 0.2. Deafault: 0.07
extern double DynSLCoeff = 1.1; // Dynamic Stop loss coefficient 0.5 to 1.5. Deafault: 1.1

const double TAKEPROFIT = 0;
const int Slippage = 3;
const datetime ExpirationOrder = 0;

string _symbol;
int _period;
double _stoplossBuy;
double _stoplossSell;
double _takeProfit;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;
double _dynamicSLExtraPoints;

CFileLog *_log;
PSSignals* _signals;
PSMarket *_market;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    _symbol = Symbol();
    _period = Period();

    string fileName = StringConcatenate("PSea_", _symbol, "_", _period, "_", SignalId, ".log");
    //Initialise _log with filename = "example.log", Level = WARNING and Print to console
    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, SignalId);

	_market = new PSMarket(_log, _symbol, _period);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    double pipPoints =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
    //_stoplossBuy = Stoploss * pipPoints;
    //_stoplossSell = Stoploss * pipPoints;

    _takeProfit = TAKEPROFIT * pipPoints;
    _commentOrder = WindowExpertName();
    _lastBarNumber = Bars;

    //_dynamicSLExtraPoints = DynamicSLExtraPoints * Point;

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   GlobalVariablesDeleteAll();
   delete _signals;
	delete _market;
   delete _log;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsTradeAllowed()) 
    {
        return;
    }

    int currentBarNumber = Bars;

    // Process logics only if new bar is arrived.
    if(currentBarNumber == _lastBarNumber)
    {
        return;
    }
    _lastBarNumber = currentBarNumber;

   int orderTicket = _market.GetFirstOpenOrder(_magicNumber);
      
   if(orderTicket != -1) {
      ProcessOpenedOrders();
   }
   
   OpenOrders();
}

bool OpenOrders()
{
    int signal = _signals.Open();
    if(signal == OP_NONE)
    {
        return true;      
    }

    // Check if it there free money.
    if((AccountFreeMarginCheck(_symbol, signal, Lot) <= 0) || (GetLastError() == 134))
    {
        _log.Error(StringConcatenate("Open new ", _symbol, " ", signal == OP_BUY ? "Buy" : "Sell", " order error: Not enough money!"));
        return false;
    }

    double dynSL = _market.GetAtrStopLoss() * DynSLCoeff;

    bool result = _market.OpenOrder(signal, Lot, dynSL, TAKEPROFIT, _magicNumber);
    if (result) {
        _market.DrawVLine(signal == OP_BUY ? clrRed : clrBlue, signal == OP_BUY ? "Buy open" : "Sell open", STYLE_DASH);
    }
    
    return result;

    // //if (DynamicStopLoss) 
    // {
    //     //double dynSL = _market.GetAtrStopLoss() + _dynamicSLExtraPoints;
    //     double dynSL = _market.GetAtrStopLoss() * DynSLCoeff;
    //     _stoplossBuy = dynSL;
    //     _stoplossSell = dynSL;
    // }

    // if (signal == OP_BUY) {
    //     double sellPrice = Ask;
    //     double slBuy = NormalizeDouble(sellPrice - _stoplossBuy, Digits);
    //     bool buyResult = OpenNewOrder(OP_BUY, sellPrice, Lot, slBuy);
    // }

    // if (signal == OP_SELL) {
    //     double buyPrice = Bid;
    //     double slSell = NormalizeDouble(buyPrice + _stoplossSell, Digits);
    //     bool sellResult = OpenNewOrder(OP_SELL, buyPrice, Lot, slSell);
    // }

    // _market.DrawVLine(signal == OP_BUY ? clrRed : clrBlue, signal == OP_BUY ? "Buy open" : "Sell open", STYLE_DASH);

    // return true /*buyResult && sellResult*/;   
}

bool OpenNewOrder(int operation, double price, double lot, double stoploss)
{
   // TODO: Recurring system.
   int ticket = OrderSend(_symbol, operation, lot, price, Slippage, stoploss, _takeProfit, _commentOrder, _magicNumber, ExpirationOrder, operation == OP_BUY ? clrRed : clrBlue);
   if(ticket == -1)
   {
      int error = GetLastError();

      _log.Error(StringConcatenate("Failed to Open New ", operation ? "Buy" : "Sell", " order ",_symbol,"! Error code = ",
            error,", ",ErrorDescription(error), "!"));

      return false;
   }
   
   return true;
}

bool ProcessOpenedOrders()
{
    int ordersTotal = OrdersTotal();

    int i = 0;
    while(i < ordersTotal)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == _symbol && OrderMagicNumber() == _magicNumber)
            {
                int signal = _signals.Close(OrderType(), CloseSignalId, DynCloseCoeff);
                if(signal != OP_NONE) 
                {
                    _market.DrawVLine(signal == OP_BUY ? clrHotPink : clrSkyBlue, signal == OP_BUY ? "Buy close" : "Sell close", STYLE_DOT);

                    if(_market.CloseOrders(_magicNumber, signal))
                    {
                        i = 0;
                        ordersTotal = OrdersTotal();
                        continue;
                    }
                }
            }
        }

        i++;
    }
   
    return true;
}