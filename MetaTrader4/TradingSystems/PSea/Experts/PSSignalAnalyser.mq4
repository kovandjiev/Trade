//+------------------------------------------------------------------+
//|                                             PSSignalAnalyser.mq4 |
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

#define MAGICNUMBER 20190122   

extern int  SignalSystemId = 1; // Signal system Id form 1 to 24

string _symbol;
int _period;
double _point;
int _lastBarNumber;
int _vlineId;

CFileLog *_log;
PSSignals* _signals;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //Initialise _log with filename = "example.log", Level = WARNING and Print to console
    _log = new CFileLog("PSea.log", INFO, true, IsOptimization());
    MarketFileLog = _log;

    if(!CheckSystems())
    {
        return INIT_FAILED;
    }

    _symbol = Symbol();
    _period = Period();

    _signals = new PSSignals(_log, _symbol, _period);

    _lastBarNumber = Bars;
    _vlineId = 1;

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

    // Open signal
    int openSignal = _signals.Signal(SignalSystemId, true);
    if(openSignal != -1)
    {
        VLineCreate(openSignal == OP_BUY ? clrRed : clrBlue, openSignal == OP_BUY ? "Buy open" : "Sell open");
    }

    // // Close signal
    // int closeSignal = _signals.Signal(SignalSystemId, false);
    // if(closeSignal != -1)
    // {
    //     VLineCreate(closeSignal == OP_BUY ? clrHotPink : clrSkyBlue);
    // }

   _lastBarNumber = currentBarNumber;
}

bool VLineCreate(const color           clr,        // line color
                 string name,
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
{
    name = StringConcatenate(name, " ", _vlineId++);
    long chart_ID=0;
    
    ResetLastError();
    if(!ObjectCreate(chart_ID, name, OBJ_VLINE, 0, TimeCurrent(), 0))
    {
        Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
        return(false);
    }

    ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
    ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
    ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
    ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
    ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
    ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);

    return true;
}

bool CheckSystems()
{
   bool checkOpenSignal = _signals.CheckSignalIdIsValid(SignalSystemId);
   bool checkCloseSignal = _signals.CheckSignalIdIsValid(SignalSystemId);
   
   if(!checkOpenSignal || !checkCloseSignal)
   {
      _log.Critical(StringConcatenate(!checkOpenSignal ? "Open" : "Close", " signal system with Id:", SignalSystemId, " is not exists."));

      return false;
   }

   return true;
}