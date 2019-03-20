//+------------------------------------------------------------------+
//|                                                        PSea6.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening order if open signal arrives. Stop loss and Take profit are dippend ATR indicator.
// Opening hedge orders if open signal arrives. If it Buy opens main order with full lot and opposite stop order with half lot (SmallLot).
// Lot calculate depend risk and free margin.
// Including Trailing Stop
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "6.0"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int SignalId = 1; // Open signal system Id form 1 to 10
extern int Risk = 15; // Percent of Risk from account from 1 to 20. Deault: 15 
extern double DynSLCoeff = 0.8; // Dynamic Stop loss coefficient 0.1 to 1.0. Default: 0.8
extern double DynTPCoeff = 2.5; // Dynamic Take profit coefficient 1.5 to 3.0 ... Default: 2.5

int DynIndicator = 1; // Dynamic indicator. 1 - Atr, 2 - StdDev Default: 1
int OpenOrderType = 1; // Open order type. Standart open 1, 2 - open hedge orders. Default: 1
// These coefficient are for OpenOrderType = 2
int StopOrdLife = 1; // Stop order life in bars coefficient 1 is 1 TF 1 to 2. Default: 1
double StopOrdDistCoeff = 1.0; // Stop order distance coefficient 0.5 to 1.5. Default: 1.0

string _symbol;
int _period;
int _digits;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;
int _stopOrderLive;

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

    string fileName = StringConcatenate("PSea6_", _symbol, "_", _period, "_", SignalId, ".log");

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
    _stopOrderLive = (int)MathRound(_period /* min */ * StopOrdLife /* bars */ * 60 /* seconds */);

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
   
    int signal = _signals.Open();
    if(signal == OP_NONE)
    {
        return;      
    }

    double dynValue = 0.0;
    switch (DynIndicator)
    {
        case 1: dynValue = _market.GetAtr(); break;
        case 2: dynValue = _market.GetStdDev(); break;
        default:
            break;
    }

    switch (OpenOrderType)
    {
        case 1: OpenOrders(signal, dynValue); break;
        case 2: OpenHedgeOrders(signal, dynValue); break;
        default:
            break;
    }
}

bool OpenOrders(int signal, double dynValue)
{
    double dynSL = dynValue * DynSLCoeff;
    double dynTP = dynValue * DynTPCoeff;

    double lot = _market.GetLotPerRisk(Risk, dynSL, signal);

    bool result = _market.OpenOrder(signal, lot, dynSL, dynTP, _magicNumber);
    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, true), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }
    
    return result;
}

bool OpenHedgeOrders(int signal, double dynValue)
{
    double dynSL = dynValue * DynSLCoeff;
    double dynTP = dynValue * DynTPCoeff;

    double lot = _market.GetLotPerRisk(Risk, dynSL, signal);
    double smallLot = NormalizeDouble(lot / 2, 2);
    double minLot = MarketInfo(_symbol, MODE_MINLOT); 
    if (smallLot < minLot) {
        smallLot = minLot;
    }
    
    double stopOrdDist = dynValue * StopOrdDistCoeff;
    //datetime expirationTime = TimeCurrent() + _stopOrderLive;
    datetime expirationTime = iTime(_symbol, _period, 0) + _stopOrderLive;

    bool result = _market.OpenHedgeOrders1M1S(signal, lot, smallLot, stopOrdDist, dynSL, dynTP, _magicNumber, expirationTime);

    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, true), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }

    return result;
}
