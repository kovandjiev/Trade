//+------------------------------------------------------------------+
//|                                                        PSea1.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
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
extern bool CloseOrderInProfit = true; // Close order only if it in profit

const double TAKEPROFIT = 0;
const double Lot = 0.1;
const int Slippage = 3;
const datetime ExpirationOrder = 0;

string _symbol;
int _period;
double _point;
double _stopLoss;
double _takeProfit;
string _commentOrder;

CFileLog *_log;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //Initialise _log with filename = "example.log", Level = WARNING and Print to console
   _log=new CFileLog("PSea.log", INFO, true, IsOptimization());

   if(!CheckSystems())
   {
      return INIT_FAILED;
   }

   _symbol = Symbol();
   _period = Period();
   _point =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
   _stopLoss = STOPLOSS * _point;
   _takeProfit = TAKEPROFIT * _point;
   _commentOrder = WindowExpertName();

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   GlobalVariablesDeleteAll();
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
   
   int orderTicket = GetFirstOpenOrder(MAGICNUMBER);
   
   if(orderTicket == -1)
   {
      OpenOrderProcessing();
   }
   else
   {
      CloseOrderProcessing();
   } 
}

bool CheckSystems()
{
   bool checkOpenSignal = CheckSignalId(OpenSignalSystemId);
   bool checkCloseSignal = CheckSignalId(CloseSignalSystemId);
   
   if(!checkOpenSignal || !checkCloseSignal)
   {
      if(!checkOpenSignal)
      {
         _log.Critical(StringConcatenate("Open signal system with Id:", OpenSignalSystemId, " is not exists."));
      }

      if(!checkCloseSignal)
      {
         _log.Critical(StringConcatenate("Close signal system with Id:", CloseSignalSystemId, " is not exists."));
      }

      return false;
   }

   return true;
}

bool OpenOrderProcessing()
{
   int signal = CheckSignal(OpenSignalSystemId, true);
   if(signal == -1)
   {
      return true;      
   }
   
   // Check if it there free money.
   if((AccountFreeMarginCheck(_symbol, signal, Lot) <= 0) || (GetLastError() == 134))
   {
      _log.Error(StringConcatenate("Open new ", _symbol, " ", signal == OP_BUY ? "Buy" : "Sell", " order error: Not enough money!"));
      return false;
   }

   if(signal == OP_BUY)
   {
      double sellPrice = Ask;
      
      double stoploss = NormalizeDouble(sellPrice - _stopLoss, Digits);
      
      return(OpenNewOrder(OP_BUY, sellPrice, stoploss));
   }

   if(signal == OP_SELL)
   {
      double buyPrice = Bid;
      
      double stoploss = NormalizeDouble(buyPrice + _stopLoss, Digits);
      
      return(OpenNewOrder(OP_SELL, buyPrice, stoploss));
   }
   
   return true;   
}

bool OpenNewOrder(int operation, double price, double stoploss)
{
   // TODO: Recurring system.
/*
   int ticket = -1;
   int i = 0;
   while(ticket == -1 && i < 3)
   {
      ticket = OrderSend(_symbol, operation, Lot, price, Slippage, stoploss, _takeProfit, _commentOrder, MAGICNUMBER, ExpirationOrder, operation == OP_BUY ? clrDeepSkyBlue : clrDeepPink);
      Sleep(5000);
      ++i;
   } 
*/
   int ticket = OrderSend(_symbol, operation, Lot, price, Slippage, stoploss, _takeProfit, _commentOrder, MAGICNUMBER, ExpirationOrder, operation == OP_BUY ? clrDeepSkyBlue : clrDeepPink);
   if(ticket == -1)
   {
      int error = GetLastError();

      _log.Error(StringConcatenate("Failed to Open New ", operation ? "Buy" : "Sell", " order ",_symbol,"! Error code = ",
            error,", ",ErrorDescription(error), "!"));

      return false;
   }

   return true;
}

bool CloseOrderProcessing()
{
   int signal = CheckSignal(CloseSignalSystemId, false);
   if(signal == -1)
   {
      return true;      
   }

   int orderType = OrderType();
   // We can add opposite logics - if current order is BUY but signal (enter) is for sell -> close the order.
   if(signal != orderType)
   {
      return true;      
   }

   if (CloseOrderInProfit && OrderProfit() <= 0.0) {
      return true;
   }
   
   return CloseOrder(orderType);
}

bool CloseOrder(int orderType)
{
   double price = orderType == OP_BUY ? Bid /*Buy*/ : Ask /*Sell*/;

   bool result = OrderClose(OrderTicket(), OrderLots(), price, Slippage, orderType == OP_BUY ? clrBlue : clrRed);

   if(!result)
   {
      int error = GetLastError();

      _log.Error(StringConcatenate("Failed to Close ", orderType ? "Buy" : "Sell", " order #", OrderTicket(), " ", _symbol,"! Error code = ",
            error,", ",ErrorDescription(error), "!"));
   }
   
   return result;
}