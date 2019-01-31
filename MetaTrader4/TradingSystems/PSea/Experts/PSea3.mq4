//+------------------------------------------------------------------+
//|                                                        PSea2.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Add hashing
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "1.00"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

#define MAGICNUMBER 20190122   

extern int    OpenSignalSystemId = 1; // Open signal system Id form 1 to 24
extern int    CloseSignalSystemId = 1; // Close signal system Id form 1 to 24
extern int    STOPLOSS = 25; // Stop loss in pips
extern double SmallLot = 0.01;

bool CloseOrderInProfit = false; // Close order only if it in profit

const double TAKEPROFIT = 0;
//const double SmallLot = 0.05;
const double Lot = SmallLot * 2;
const int Slippage = 3;
const datetime ExpirationOrder = 0;

string _symbol;
int _period;
double _point;
double _stopLoss;
double _takeProfit;
string _commentOrder;
int _lastBarNumber;
int _currentBarNumber;
int _lastOrderType;

CFileLog *_log;
PSSignals* _signals;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //Initialise _log with filename = "example.log", Level = WARNING and Print to console
    _log=new CFileLog("PSea.log", INFO, true, IsOptimization());
    MarketFileLog = _log;

    if(!CheckSystems())
    {
        return INIT_FAILED;
    }

    _symbol = Symbol();
    _period = Period();

    _signals = new PSSignals(_log, _symbol, _period);

    _point =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
    _stopLoss = STOPLOSS * _point;
    _takeProfit = TAKEPROFIT * _point;
    _commentOrder = WindowExpertName();
    _lastBarNumber = Bars;
    _currentBarNumber = _lastBarNumber;
    _lastOrderType = -1;

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

   _currentBarNumber = Bars;

   // It prevent to open a lot of position per bar.
   if(_currentBarNumber == _lastBarNumber)
   {
      return;
   }

   int orderTicket = GetFirstOpenOrder(_symbol, MAGICNUMBER);
      
   if(orderTicket == -1)
   {
       _lastOrderType = -1;
      OpenHedgeOrders();
   }
   else
   {
      //CloseOrderProcessing();
      ProcessOpenedHedgeOrders(OrderType());
   }

   _lastBarNumber = _currentBarNumber;
}

bool CheckSystems()
{
   bool checkOpenSignal = _signals.CheckSignalIdIsValid(OpenSignalSystemId);
   bool checkCloseSignal = _signals.CheckSignalIdIsValid(CloseSignalSystemId);
   
   if(!checkOpenSignal || !checkCloseSignal)
   {
      _log.Critical(StringConcatenate(!checkOpenSignal ? "Open" : "Close", " signal system with Id:", OpenSignalSystemId, " is not exists."));

      return false;
   }

   return true;
}

bool OpenHedgeOrders()
{
    int signal = _signals.Signal(OpenSignalSystemId, true);
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
   
        _lastOrderType = signal;
    }

    if(signal == OP_SELL)
    {
        sellLot = Lot;

        _lastOrderType = signal;
    }

    double sellPrice = Ask;
    double stoplossBuy = NormalizeDouble(sellPrice - _stopLoss, Digits);
    bool buyResult = OpenNewOrder(OP_BUY, sellPrice, buyLot, stoplossBuy);

    double buyPrice = Bid;
    double stoplossSell = NormalizeDouble(buyPrice + _stopLoss, Digits);
    bool sellResult = OpenNewOrder(OP_SELL, buyPrice, sellLot, stoplossSell);


    return buyResult && sellResult;   
}

bool OpenNewOrder(int operation, double price, double lot, double stoploss)
{
   // TODO: Recurring system.
   int ticket = OrderSend(_symbol, operation, lot, price, Slippage, stoploss, _takeProfit, _commentOrder, MAGICNUMBER, ExpirationOrder, operation == OP_BUY ? clrDeepSkyBlue : clrDeepPink);
   if(ticket == -1)
   {
      int error = GetLastError();

      _log.Error(StringConcatenate("Failed to Open New ", operation ? "Buy" : "Sell", " order ",_symbol,"! Error code = ",
            error,", ",ErrorDescription(error), "!"));

      return false;
   }
   
   return true;
}
/*
bool CloseOrderProcessing()
{
   int signal = _signals.Signal(CloseSignalSystemId, false);
   if(signal == -1)
   {
      return true;      
   }

   int orderType = OrderType();
   // TODO: We can add opposite logics - if current order is BUY but signal (enter) is for sell -> close the order.
   if(signal != orderType)
   {
      return true;      
   }

   if (CloseOrderInProfit && OrderProfit() <= 0.0) {
      return true;
   }
   
   return CloseOrder(OrderTicket(), OrderLots(), orderType, Slippage);
}
*/
bool ProcessOpenedHedgeOrders(int firstOrderType)
{
   int signal = _signals.Signal(CloseSignalSystemId, false);
   if(signal == -1)
   {
      return true;      
   }

    int orderCount = GetOpenedOrderCount(_symbol, MAGICNUMBER);
    // Close loss order
    // if (orderCount > 1) {
        
    // }

    // Is only order ocurred get it type add wait signal to close.
    if (orderCount == 1) {
        _lastOrderType = firstOrderType;
    }

   if(signal != _lastOrderType)
   {
      return true;      
   }

   return CloseOrders(_symbol, MAGICNUMBER, Slippage);
}