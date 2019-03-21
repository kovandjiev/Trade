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
#property version   "6.1"
#property strict

#include <PSSignals.mqh>
#include <PSTrailingSL.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int OpenSignalId = 1; // Open signal system Id form 1 to 10
extern int TrailingSystemId = 1; // Trailing stop loss system Id form 1
extern int Risk = 15; // Percent of Risk from account from 1 to 20. Deault: 15 
extern double StopLossCoeff = 0.5; // Stop loss coefficient 0.1 to 1.0. Default: 0.5
// extern double DynTPCoeff = 2.5; // Dynamic Take profit coefficient 1.5 to 3.0 ... Default: 2.5

string _symbol;
int _period;
int _digits;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

CFileLog *_log;
PSSignals* _signals;
PSTrailingSL* _trailing;
PSMarket *_market;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    _symbol = Symbol();
    _period = Period();
    _digits = Digits;

    string fileName = StringConcatenate("PSea6_", _symbol, "_", _period, "_", OpenSignalId, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, OpenSignalId, _digits);
    if(!_signals.IsInitialised())
    {
        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    _trailing = new PSTrailingSL(_log, _symbol, _period, _digits, TrailingSystemId);
    if(!_trailing.IsInitialised())
    {
        return INIT_FAILED;
    }

    _market = new PSMarket(_log, _symbol, _period, _digits);
    if (!_market.IsInitialised()) {
        return INIT_FAILED;
    }

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
    delete _trailing;
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

    ProcessTrailingStop();
    
    int signal = _signals.Open();
    if(signal == OP_NONE)
    {
        return;      
    }

    double sl = _trailing.GetStopLoss();

    OpenOrders(signal, sl);
}

bool OpenOrders(int signal, double sl)
{
    double tp = 0;

    double lot = _market.GetLotPerRisk(Risk, sl, signal);

    bool result = _market.OpenOrder(signal, lot, sl, tp, _magicNumber);
    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, OpenOperation), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }
    
    return result;
}

bool ProcessTrailingStop()
{
    bool result = true;
    int ordersTotal = OrdersTotal();

    for(int i = 0; i < ordersTotal; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == _symbol && OrderMagicNumber() == _magicNumber)
            {
                int orderType = OrderType();
                double sl = _trailing.GetStopLoss(orderType, StopLossCoeff);

                result = result && _market.ModifyOpenedOrderSL(OrderTicket(), orderType, sl);
            }
        }
    }
    
    return result;
}