//+------------------------------------------------------------------+
//|                                                      PSea7_0.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening only one order if it closed opens another one. 
// Stop loss calculated from Trailing SL.
// No Take profit.
// Lot calculate depend risk and free margin.
// Including Trailing Stop
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "7.0"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

input int OpenSignalId = 1; // Open signal system Id form 1 to 72
input int Risk = 1; // Percent of Risk from account from 1 to 20. Deault: 1 
input double DynTPCoeff = 1; // Dynamic Take profit coefficient 0.5 to 3.0 ... Default: 1
input int DynIndicator = 1; // Dynamic indicator. 1 - Atr, 2 - StdDev, 3 - Mfi. Default: 1

string _symbol;
int _period;
int _digits;
double _points;
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
    _points = Point;
    
    _commentOrder = StringConcatenate("PSeaH7_0_", _symbol, "_", _period, "_", OpenSignalId);
    string fileName = StringConcatenate(_commentOrder, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, OpenSignalId, _digits, _points);
    if(!_signals.IsInitialised())
    {
        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber(70/*EA version*/*1000);
    //_magicNumberOpp = _magicNumberBase /*+ 1*/;

    _market = new PSMarket(_log, _symbol, _period, _digits, _points);
    if (!_market.IsInitialised()) {
        return INIT_FAILED;
    }

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
    if(!IsTradeAllowed() || IsTradeContextBusy()) 
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

    if (_market.GetFirstOpenOrder(_magicNumber) != -1)
    {
        // There is order for processing.
        return;
    }

    // Delete unnecessary pending order.
    _market.DeleteOrder(_magicNumber);

    int orderType = _signals.Open();
    if(orderType == OP_NONE)
    {
        return;      
    }

    OpenOrders(orderType);
}

bool OpenOrders(int orderType)
{
    double dynValue = 0.0;
    switch (DynIndicator)
    {
        case 1: dynValue = _market.GetAtr(); break;
        case 2: dynValue = _market.GetStdDev(); break;
        case 3: dynValue = _market.GetMfi(); break;
        default:
            break;
    }

    double dynTP = dynValue * DynTPCoeff;

    double lot = _market.GetLotPerRisk(Risk, dynTP * 2, orderType);
    //Print(StringConcatenate("Open order signal: ", orderType, ", SL: ", sl, ", Lot: ", lot));

    bool result = _market.OpenHedgeOrder1To2(orderType, lot, dynTP, _magicNumber, _magicNumber);

    if (IsTesting() && result) {
        _market.DrawVLine(_market.OrderTypeToColor(orderType, OpenOperation), StringConcatenate(_market.OrderTypeToString(orderType), " open"), STYLE_DASH);
    }
    
    return result;
}