//+------------------------------------------------------------------+
//|                                             PSAllTF_Template.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening order if open signal arrives. Stop loss and Take profit are dippend ATR indicator.
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "5.30"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int PeriodId = 2; // Period 2 to 6

extern int SignalId = 1; // Open signal system Id form 1 to 8
extern double Lot = 0.01; // Open order Lot
extern double DynSLCoeff = 1.0; // Dynamic Stop loss coefficient 0.5 to 1.5. Default: 1.1
extern double DynTPCoeff = 2.0; // Dynamic Take profit coefficient 0.5 to 1.0, 2.0 ... Default: 2.0

string _symbol;
int _period;
int _digits;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

CFileLog *_log;
PSMarket *_market;
PSSignals* _signals;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if (!IsOptimization() || !IsTesting()) {

        Print("This advisor should be run only in optimisation or backtest mode!");
        return INIT_FAILED;
    }

    _symbol = Symbol();
    
    _period = GetTimeFrameByIndex(PeriodId);
    if (_period == 0) 
    {
        Print(StringConcatenate("Invalid Time frame id: ", PeriodId));
        return INIT_FAILED;
    }

    string fileName = StringConcatenate("PSAllTest_", _symbol, "_", _period, "_", SignalId, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _digits = (int)MarketInfo(_symbol, MODE_DIGITS); 

    _signals = new PSSignals(_log, _symbol, _period, SignalId, _digits);

	_market = new PSMarket(_log, _symbol, _period, _digits);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    //double pipPoints =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
    //_stoplossBuy = Stoploss * pipPoints;
    //_stoplossSell = Stoploss * pipPoints;

    //_takeProfit = TAKEPROFIT * pipPoints;
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
    delete _signals;
    delete _market;
    delete _log;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
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

    bool result = _market.OpenOrder(signal, Lot, dynSL, dynTP, _magicNumber);
    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, true), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }
    
    return result;
}