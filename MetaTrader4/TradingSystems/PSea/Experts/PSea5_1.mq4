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

extern int SignalId = 1; // Open signal system Id form 1 to 8
extern int Stoploss = 25; // Stop loss in pips
extern double SmallLot = 0.01;
extern bool CloseSignal = false; // Close signal system

const double TAKEPROFIT = 0;
const double Lot = SmallLot * 2;
const int Slippage = 3;
const datetime ExpirationOrder = 0;

string _symbol;
int _period;
double _point;
double _stoplossBuy;
double _stoplossSell;
double _takeProfit;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

CFileLog *_log;
PSSignals* _signals;

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
    MarketFileLog = _log;

    _signals = new PSSignals(_log, _symbol, _period, SignalId);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    _point =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
    _stoplossBuy = Stoploss * _point;
    _stoplossSell = Stoploss * _point;

    _takeProfit = TAKEPROFIT * _point;
    _commentOrder = WindowExpertName();
    _lastBarNumber = Bars;

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   GlobalVariablesDeleteAll();
   delete _signals;
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

    int orderTicket = GetFirstOpenOrder(_symbol, _magicNumber);

    if(orderTicket != -1) {
        ProcessOpenedOrders();
    }

    OpenHedgeOrders();
}

bool OpenHedgeOrders()
{
    int signal = _signals.Open();
    if(signal == -1)
    {
        return true;      
    }

    // Check if it there free money.
    if((AccountFreeMarginCheck(_symbol, signal, Lot + SmallLot) <= 0) || (GetLastError() == 134))
    {
        _log.Error(StringConcatenate("Open new ", _symbol, " ", signal == OP_BUY ? "Buy" : "Sell", " order error: Not enough money!"));
        return false;
    }

    double buyLot = SmallLot;
    double sellLot = SmallLot;

    if(signal == OP_BUY)
    {
        buyLot = Lot;
    }

    if(signal == OP_SELL)
    {
        sellLot = Lot;
    }

    double sellPrice = Ask;
    double slBuy = NormalizeDouble(sellPrice - _stoplossBuy, Digits);
    bool buyResult = OpenNewOrder(OP_BUY, sellPrice, buyLot, slBuy);

    double buyPrice = Bid;
    double slSell = NormalizeDouble(buyPrice + _stoplossSell, Digits);
    bool sellResult = OpenNewOrder(OP_SELL, buyPrice, sellLot, slSell);

    VLineCreate(signal == OP_BUY ? clrRed : clrBlue, signal == OP_BUY ? "Buy open" : "Sell open", STYLE_DASH);

    return buyResult && sellResult;   
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
                int signal = _signals.Close(OrderType(), CloseSignal);
                if(signal != OP_NONE) 
                {
                    VLineCreate(signal == OP_BUY ? clrHotPink : clrSkyBlue, signal == OP_BUY ? "Buy close" : "Sell close", STYLE_DOT);

                    if(CloseOrders(_symbol, _magicNumber, Slippage, signal))
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