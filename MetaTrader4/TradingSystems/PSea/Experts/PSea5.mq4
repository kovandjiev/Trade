//+------------------------------------------------------------------+
//|                                                        PSea5.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening order if open signal arrives. Close orders if close signal from this type arrives.
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "5.00"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int SignalId = 1; // Open signal system Id form 1 to 8
extern int CloseSignalId = 1; // Close signal system 1 to 3
extern double Lot = 0.01; // Open order Lot
extern double DynCloseCoeff = 0.07; // Dynamic close order coefficient 0.01 to 0.2. Default: 0.07
extern double DynSLCoeff = 1.1; // Dynamic Stop loss coefficient 0.5 to 1.5. Default: 1.1

const double TAKEPROFIT = 0;
const int Slippage = 3;
const datetime ExpirationOrder = 0;

string _symbol;
int _period;
double _stoplossBuy;
double _stoplossSell;
double _takeProfit;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;
double _dynamicSLExtraPoints;

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

    string fileName = StringConcatenate("PSea5_", _symbol, "_", _period, "_", SignalId, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, SignalId);

	_market = new PSMarket(_log, _symbol, _period);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    double pipPoints =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
    //_stoplossBuy = Stoploss * pipPoints;
    //_stoplossSell = Stoploss * pipPoints;

    _takeProfit = TAKEPROFIT * pipPoints;
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

   GlobalVariablesDeleteAll();
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

    int currentBarNumber = Bars;

    // Process logics only if new bar is arrived.
    if(currentBarNumber == _lastBarNumber)
    {
        return;
    }
    _lastBarNumber = currentBarNumber;

   int orderTicket = _market.GetFirstOpenOrder(_magicNumber);
      
   if(orderTicket != -1) {
      ProcessOpenedOrders();
   }
   
   OpenOrders();
}

bool OpenOrders()
{
    int signal = _signals.Open();
    if(signal == OP_NONE)
    {
        return true;      
    }

    double dynSL = _market.GetAtrStopLoss() * DynSLCoeff;

    bool result = _market.OpenOrder(signal, Lot, dynSL, TAKEPROFIT, _magicNumber);
    if (result) {
        _market.DrawVLine(_market.OrderTypeToColor(signal, true), StringConcatenate(_market.OrderTypeToString(signal), " open"), STYLE_DASH);
    }
    
    return result;
}

bool ProcessOpenedOrders()
{
    int ordersTotal = OrdersTotal();

    int i = 0;
    while(i < ordersTotal)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == _symbol && OrderMagicNumber() == _magicNumber)
            {
                int signal = _signals.Close(OrderType(), CloseSignalId, DynCloseCoeff);
                if(signal != OP_NONE) 
                {
                    _market.DrawVLine(_market.OrderTypeToColor(signal, false), StringConcatenate(_market.OrderTypeToString(signal), " close"), STYLE_DOT);

                    if(_market.CloseOrders(_magicNumber, signal))
                    {
                        i = 0;
                        ordersTotal = OrdersTotal();
                        continue;
                    }
                }
            }
        }

        i++;
    }
   
    return true;
}