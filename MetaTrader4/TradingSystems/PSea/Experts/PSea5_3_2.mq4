//+------------------------------------------------------------------+
//|                                                    PSea5_3_2.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening order if open signal arrives. Stop loss and Take profit are dippend ATR indicator.
// Lot calculate depend risk and free martin.
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "5.30"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int SignalId = 1; // Open signal system Id form 1 to 8
extern int Risk = 1; // Percent of Risk from account
extern double DynSLCoeff = 1.0; // Dynamic Stop loss coefficient 0.5 to 1.5. Default: 1.1
extern double DynTPCoeff = 3.0; // Dynamic Take profit coefficient 0.5 to 1.0, 2.0 ... Default: 3.0

string _symbol;
int _period;
int _digits;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

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
    _digits = Digits;

    string fileName = StringConcatenate("PSea5_3_2_", _symbol, "_", _period, "_", SignalId, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, SignalId, _digits);

	_market = new PSMarket(_log, _symbol, _period, _digits);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    _commentOrder = WindowExpertName();
    _lastBarNumber = iBars(_symbol, _period);

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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

    int currentBarNumber = iBars(_symbol, _period);

    // Process logics only if new bar is arrived.
    if(currentBarNumber == _lastBarNumber)
    {
        return;
    }
    _lastBarNumber = currentBarNumber;
   
   OpenOrders();
}

bool OpenOrders()
{
    int signal = _signals.Open();
    if(signal == OP_NONE)
    {
        return true;      
    }

    double atr = _market.GetIndicatorAtr();
    double dynSL = atr * DynSLCoeff;
    double dynTP = atr * DynTPCoeff;

    double lot = _market.GetLotPerRisk(Risk, dynSL, signal);

    bool result = _market.OpenOrder(signal, lot, dynSL, dynTP, _magicNumber);
    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, true), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }
    
    return result;
}