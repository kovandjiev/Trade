//+------------------------------------------------------------------+
//|                                                      PSea6_2.mq4 |
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
#property version   "6.1"
#property strict

#include <PSSignals2.mqh>
#include <PSTrailingSL.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int OpenSignalId = 1; // Open signal system Id form 1 to 10
extern int TrailingSystemId = 1; // Trailing stop loss system Id form 1
extern int Risk = 15; // Percent of Risk from account from 1 to 20. Deault: 15 
extern double StopLossCoeff = 0.5; // Stop loss coefficient 0.0 to 1.0. Default: 0.5

string _symbol;
int _period;
int _digits;
double _points;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

CFileLog *_log;
PSSignals2* _signals;
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
    _points = Point;
    
    _commentOrder = StringConcatenate("PSea6_2_", _symbol, "_", _period, "_", OpenSignalId, "_", TrailingSystemId);
    string fileName = StringConcatenate(_commentOrder, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals2(_log, _symbol, _period, OpenSignalId, _digits, _points);
    if(!_signals.IsInitialised())
    {
        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    _trailing = new PSTrailingSL(_log, _symbol, _period, _digits, _points, TrailingSystemId, StopLossCoeff);
    if(!_trailing.IsInitialised())
    {
        return INIT_FAILED;
    }

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
    delete _trailing;
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

    if(ProcessTrailingStop())
    {
        return;
    }
    
    int orderType = _signals.Open();
    if(orderType == OP_NONE)
    {
        return;      
    }

    int sl = _trailing.GetStopLoss(orderType);
    //Print(StringConcatenate("SL:", sl));

    OpenOrders(orderType, sl);
}

bool OpenOrders(int orderType, int sl)
{
    int tp = 0;

    double lot = _market.GetLotPerRisk(Risk, sl, orderType);
    //Print(StringConcatenate("Open order signal: ", orderType, ", SL: ", sl, ", Lot: ", lot));

    bool result = _market.OpenOrder(orderType, lot, sl, tp, _magicNumber);
    if (IsTesting() && result) {
        _market.DrawVLine(_market.OrderTypeToColor(orderType, OpenOperation), StringConcatenate(_market.OrderTypeToString(orderType), " open"), STYLE_DASH);
    }
    
    return result;
}

bool ProcessTrailingStop()
{
    bool result = false;
    int ordersTotal = OrdersTotal();

    for(int i = 0; i < ordersTotal; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == _magicNumber)
            {
                int orderType = OrderType();
                int sl = _trailing.GetStopLoss(orderType);
                //Print(StringConcatenate("Modify SL:", sl));

                _market.ModifyOpenedOrderSL(OrderTicket(), orderType, sl);

                result = true;
            }
        }
    }
    
    return result;
}