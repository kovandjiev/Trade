//+------------------------------------------------------------------+
//|                                                         PSea.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "1.00"
#property strict

#include <PSSignals.mqh>
#include <PSTrailingFuncLib.mqh>
#include <PSMarketLib.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

#define MAGICNUMBER 20190122   

extern int    SignalSystemId = 1; // Signal trading system Id form 1 to 24
extern int    TSLSystemId = 1; // Trailing system Id from 1 to 11
extern int    STOPLOSS = 25; // Stop loss in pips
extern bool  TrailingInLoss = true; // Trailing if order in loss

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
   _log=new CFileLog("PSea.log",TRACE,true, IsOptimization());

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
      ProcessTrailingStop(TSLSystemId, orderTicket, _period /*GetPreviousTimeFrame(_period, 1)*/, true);
   } 
}

bool CheckSystems()
{
   bool checkTrailingStop = CheckTrailingStopId(TSLSystemId);
   bool checkSignal = CheckSignalId(SignalSystemId);
   
   if(!checkTrailingStop || !checkSignal)
   {
      if(!checkSignal)
      {
         _log.Critical(StringConcatenate("Signal system with Id:", SignalSystemId, " is not exists."));
      }

      if(!checkTrailingStop)
      {
         _log.Critical(StringConcatenate("Trailing system with Id:", TSLSystemId, " is not exists."));
      }

      return false;
   }

   return true;
}

bool OpenOrderProcessing()
{
   int signal = CheckSignal(SignalSystemId);
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