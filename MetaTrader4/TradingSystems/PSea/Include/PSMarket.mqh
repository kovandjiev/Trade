//+------------------------------------------------------------------+
//|                                                     PSMarket.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property library
#property strict

#include <FileLog.mqh>
#include <stdlib.mqh>

#define TimeFrameCount 9
#define SymbolCount 9

enum OperationType
{
   OpenOperation,
   CloseOperation,
   ModifyOperation
};

//                                         0,         1,          2,          3,         4,         5,         6,         7,          8
int TimeFrames[TimeFrameCount] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1 };
//                                         0,        1,        2,        3,        4,        5,       6
string UsedSymbols[SymbolCount] = { "EURUSD", "USDJPY", "GBPUSD", "USDCHF", "USDCAD", "AUDUSD", "NZDUSD" };

const int OP_NONE = -1;

// int GetPreviousTimeFrame(int period, short periodDown = 1);
// int GetNextTimeFrame(int period, short periodDown = 1);

// bool IsSymbolValid(string symbol);
// int GetSymbolIndex(string symbol);
// string GetSymbolByIndex(int id);

// bool IsTimeFrameValid(int period);
// int GetTimeFrameIndex(int period);
// int GetTimeFrameByIndex(int id);

class PSMarket
{
  	public:
		PSMarket(CFileLog *fileLog, string symbol, int period, int digits, double points);
		~PSMarket();
      bool IsInitialised();
      
      int GetFirstOpenOrder(int magicNumber);
      int GetOpenedOrderCount(int magicNumber);
      bool GetOrderByTicket(int ticketId);
      
      string GetLastOperationError();

      int GetSpread();
      double GetSpreadPoints();

      double PointsToPips(double points);

      bool DrawVLine(const color clr, string name, const ENUM_LINE_STYLE style=STYLE_SOLID,
                     const int width = 1, const bool back = false, const bool selection = true,
                     const bool hidden = true, const long z_order = 0);
      string OrderTypeToString(int orderType);
      color OrderTypeToColor(int orderType, OperationType operationType);
      
      // Close orders
      bool CloseOrder(int ticketId);
      bool CloseOrder(int ticketId, double lot, int orderType);
      bool CloseOrders(int magicNumber, int orderType = -1);
      
      // Delete pending orders
      bool DeleteOrder(int magicNumber);

      // Open orders
      bool OpenOrder(int orderType, double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL);
      bool OpenOrder(int orderType, double lot, int stopLoss = 0, int takeProfit = 0, int magicNumber = 0, string comment = NULL);
      bool OpenBuyOrder(double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL);
      bool OpenSellOrder(double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL);

      // Send Stop orders
      bool SendStopOrder(int orderType, double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0);
      bool SendBuyStopOrder(double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0);
      bool SendSellStopOrder(double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0);

      // Open hedge orders simultaneously
      bool OpenHedgeOrders2M(int baseOrderType, double baseLot, double oppLot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0);
      bool OpenHedgeOrders1M1S(int baseOrderType, double baseLot, double oppLot, double oppOrdDistace, double stopLoss = 0, 
               double takeProfit = 0, int magicNumber = 0, datetime oppOrderExp = 0);

      bool OpenHedgeOrder1To2(int orderType, double lot, double takeProfit = 0, int magicNumberBase = 0, int magicNumberOpp = 0);
     
      bool ModifyOpenedOrderSL(int ticketId, int orderType, int stoploss, datetime expiration = 0,
         bool trailingInLoss = true);

      double GetLotPerRisk(int riskPercent, int stopLoss, int orderType);
      double GetLotPerRisk(int riskPercent, double stopLoss, int orderType);

      // Indicators
     	double GetAtr();
     	double GetMfi();
      double GetStdDev();

	private:
		CFileLog *_log;
		string _symbol;
		int _period;
	   int _digits;
		double _points;
      int _slippage;
      double _bid;
      double _ask;

		bool _isInitialised;
		void CheckInputValues();
      int _vlineId;
      string _lastError;

      bool OpenSendInt(int orderType, double lot, double price, double stopLoss = 0, double takeProfit = 0, 
         string commentOrder = NULL, int magicNumber = 0, datetime expiration = 0);

      bool ModifyOpenedOrderSLInt(int ticketId, int orderType, double stopLoss, datetime expiration = 0,
         bool trailingInLoss = true);

      bool ModifyOpenedOrderInt(int ticketId, int orderType, double stopLoss = -1, double takeProfit = -1, 
         datetime expiration = 0);

      void LogError(string message);
      void GetCurrentBidAsk();
};

PSMarket::PSMarket(CFileLog *fileLog, string symbol, int period, int digits, double points)
{
   // slippage is usually specified as 0-3 points.
   _slippage = 3;
	_log = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = digits;
	_points = points;

	_isInitialised = false;

	CheckInputValues();

	if (_isInitialised) 
	{

	}

   _vlineId = 1;
}

PSMarket::~PSMarket()
{
}

void PSMarket::CheckInputValues()
{
   bool log = _log != NULL;
	if (!log) {
		//_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		Print(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		return;
	}

	bool symbol = IsSymbolValid(_symbol);
	if (!symbol) {
		_log.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = IsTimeFrameValid(_period);
	if (!period) {
		_log.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

   _isInitialised = log && symbol && period;

	if (!_isInitialised) 
	{
		_log.Error(StringConcatenate(__FUNCTION__, " PSMarket is not initialised!"));
	}
	else
	{
		_log.Info(StringConcatenate(__FUNCTION__, " PSMarket is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period));
	}
}

bool PSMarket::IsInitialised()
{
	return _isInitialised;
}

string PSMarket::GetLastOperationError()
{
   return _lastError;
}

bool IsSymbolValid(string symbol)
{
   return GetSymbolIndex(symbol) > -1;
}

int GetSymbolIndex(string symbol)
{
   for(int i = 0; i < SymbolCount; i++)
   {
      
      if (UsedSymbols[i] == symbol) 
      {
         return i;
      }
   }

   return -1;
}

string GetSymbolByIndex(int id)
{
   if (id < 0 || id >= SymbolCount) {
      return "";
   }
   
   return UsedSymbols[id];
}

bool IsTimeFrameValid(int period)
{
   return GetTimeFrameIndex(period) > -1;
}

// @brief Get Time frame index.
// @param period: time frame period.
// @return int -1 can not get previous period
//   Example: period = PERIOD_M1, result: 0.
int GetTimeFrameIndex(int period)
{
   for(int i = 0; i < TimeFrameCount; i++)
   {
      
      if (TimeFrames[i] == period) 
      {
         return i;
      }
   }

   return -1;
}


int GetTimeFrameByIndex(int id)
{
   if (id < 0 || id >= TimeFrameCount) {
      return 0;
   }
   
   return TimeFrames[id];
}


// @brief Get previous TF.
//   If period = PERIOD_H1, result: PERIOD_M30.
// @param period: finded period from which gets previos.
// @paramperiodDown: it should be form 1 to 8;
// @return int -1 can not get previous period
int GetPreviousTimeFrame(int period, short periodDown = 1)
{
   int tf = GetTimeFrameIndex(period);
   if (tf == -1) {
      return -1;
   }
   
   int newTFPeriod = tf - periodDown;
   // Check if first period found or previous period lover than 0.
   if (tf == 0 || (newTFPeriod < 0)) {
      return -1;
   }
   
   return TimeFrames[newTFPeriod];
}

// @brief Get next TF.
//   If period = PERIOD_H1, result: PERIOD_H4.
// @param period: finded period from which gets next.
// @paramperiodDown: it should be form 0 to 7;
// @return int -1 can not get next period
int GetNextTimeFrame(int period, short periodDown = 1)
{
   int tf = GetTimeFrameIndex(period);
   if (tf == -1) {
      return -1;
   }
   
   int newTFPeriod = tf + periodDown;
   // Check is greater than TF count.
   if (newTFPeriod >= TimeFrameCount) {
      return -1;
   }
   
   return TimeFrames[newTFPeriod];
}

// @brief Spliting stiring separated by comma.
// @param text: Input string exp.: "name1@mail.com, name2@mail.com"
// @param result: "name1@mail.com", "name2@mail.com"
// @param count: Separated strings count.
// @return bool true - if text contains 1 or more strings, false, the text is empty.
bool SplitString(const string text, string &result[], int &count)
{
   count = 0;
   ushort u_sep = StringGetCharacter(",", 0);

   count = StringSplit(text, u_sep, result); 
   
   if (count <= 0) 
   {
      return false;
   }

   return true;
}

bool PSMarket::CloseOrder(int ticketId, double lot, int orderType)
{
   GetCurrentBidAsk();

   double price = orderType == OP_BUY ? _bid /*Buy*/ : _ask /*Sell*/;

   bool result = OrderClose(ticketId, lot, price, _slippage, OrderTypeToColor(orderType, CloseOperation));

   if(!result)
   {
      LogError(StringConcatenate(__FUNCTION__, " Failed to Close order #", OrderTicket(), " of type: ", OrderTypeToString(orderType)));
   }
   
   return result;
}

bool PSMarket::CloseOrder(int ticketId)
{
   if (!GetOrderByTicket(ticketId))
      return false;
   
   int orderType = OrderType();

   return CloseOrder(ticketId, OrderLots(), orderType);
}

bool PSMarket::DeleteOrder(int magicNumber)
{
   bool result = true;

   //Print(StringConcatenate("ordersTotal: ", OrdersTotal()));
   // Closing depend order type.
   int i = 0;
   while(i < OrdersTotal())
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == _symbol && OrderMagicNumber() == magicNumber)
         {
            int orderType = OrderType();
            if(orderType == OP_BUYLIMIT || orderType == OP_SELLLIMIT || 
               orderType == OP_BUYSTOP || orderType == OP_SELLSTOP)
            {
               //Print(StringConcatenate("close order: #", OrderTicket()));
               if (OrderDelete(OrderTicket())) 
               {
                  i = 0;
                  continue;
               }
               else 
               {
                  result = false;
               }
            }
         }
      }
      i++;
   }
   
   return result;
}

bool PSMarket::CloseOrders(int magicNumber, int orderType = -1)
{
   bool result = true;

   //Print(StringConcatenate("ordersTotal: ", OrdersTotal()));
   // Closing depend order type.
   int i = 0;
   while(i < OrdersTotal())
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == _symbol && OrderMagicNumber() == magicNumber)
         {
            if(orderType == OP_NONE || OrderType() == orderType)
            {
               //Print(StringConcatenate("close order: #", OrderTicket()));
               if (CloseOrder(OrderTicket(), OrderLots(), OrderType())) 
               {
                  i = 0;
                  continue;
               }
               else 
               {
                  result = false;
               }
            }
         }
      }
      i++;
   }
   
   return result;
}

// Finding opened order.
//  If open order is found return order ticket.
//  if none orders return -1.
int PSMarket::GetFirstOpenOrder(int magicNumber)
 {
   int ordersTotal = OrdersTotal();
   
   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == _symbol) && OrderMagicNumber() == magicNumber)
         {
            // Checking is order opened.
            int orderType = OrderType();
            if (orderType == OP_BUY || orderType == OP_SELL)
            {
               return(OrderTicket());
            }

            break;
         }
      }
   }
   
   return -1;
}

int PSMarket::GetOpenedOrderCount(int magicNumber)
{
   int ordersTotal = OrdersTotal();
   int result = 0;

   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == _symbol) && OrderMagicNumber() == magicNumber)
         {
            result++;
         }
      }
   }
   
   return result;
}

bool PSMarket::GetOrderByTicket(int ticketId)
{
   return OrderSelect(ticketId, SELECT_BY_TICKET);
}

int PSMarket::GetSpread()
{
// // https://docs.mql4.com/marketinformation/symbolinfodouble   
// //--- obtain spread from the symbol properties
//    bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT);
//    string comm=StringFormat("Spread %s = %I64d points\r\n",
//                             spreadfloat?"floating":"fixed",
//                             SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
// //--- now let's calculate the spread by ourselves
//    double ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
//    double bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//    double spread=ask-bid;
//    int spread_points=(int)MathRound(spread/SymbolInfoDouble(Symbol(),SYMBOL_POINT));
//    comm=comm+"Calculated spread = "+(string)spread_points+" points";
//    Comment(comm);   
   return (int)SymbolInfoInteger(_symbol, SYMBOL_SPREAD);
}

double PSMarket::GetSpreadPoints()
{
   GetCurrentBidAsk();
   double spread = _ask - _bid;

   // If the spread is too small return 15 points.
   if (spread <= 0) {
      spread = 15 * Point;
   }
   
   return NormalizeDouble(spread, _digits);
}

bool PSMarket::DrawVLine(const color           clr,        // line color
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
            ": failed to create a vertical line! Error code = ", GetLastError());
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

// @brief Open order direct on the market.
// @param orderType OP_BUY or OP_SELL
// @param stopLoss in points.
// @param takeProfit in points.
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenOrder(int orderType, double lot, int stopLoss = 0, int takeProfit = 0, int magicNumber = 0, string comment = NULL)
{
   return OpenOrder(orderType, lot, (stopLoss * _points), (takeProfit * _points), magicNumber, comment);
}


// @brief Open order direct on the market.
// @param orderType OP_BUY or OP_SELL
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenOrder(int orderType, double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL)
{
   if (orderType != OP_BUY && orderType != OP_SELL) {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", OrderTypeToString(orderType)));
      return false;
   }

   double price = 0;
   double sl = 0;
   double tp = 0;
   GetCurrentBidAsk();
   if (orderType == OP_BUY) 
   {
        price = _ask;
        sl = _bid - stopLoss;
        tp = _bid + takeProfit;
   }

   if (orderType == OP_SELL) {
        price = _bid;
        sl = _ask + stopLoss;
        tp = _ask - takeProfit;
   }

   if (stopLoss == 0) {
      sl = 0;
   }

   if (takeProfit == 0) {
      tp = 0;
   }
   
   sl = NormalizeDouble(sl, _digits);
   tp = NormalizeDouble(tp, _digits);

   bool result = OpenSendInt(orderType, lot, price, sl, tp, comment, magicNumber);
   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open order."));
   }
   
   return result;
}

// @brief Send BuyStop order.
// @param distance from current price in points. Should be calculated 0.0010
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @param expiration Expiration time. If the order is not opened it expire. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::SendBuyStopOrder(double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0)
{
   bool result = SendStopOrder(OP_BUYSTOP, lot, distance, stopLoss, takeProfit, magicNumber, expiration);

   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot send BuyStop order."));
   }

   return result;
}

// @brief Send SellStop order.
// @param distance from current price in points. Should be calculated 0.0010
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @param expiration Expiration time. If the order is not opened it expire. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::SendSellStopOrder(double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0)
{
   bool result = SendStopOrder(OP_SELLSTOP, lot, distance, stopLoss, takeProfit, magicNumber, expiration);

   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot send SellStop order."));
   }

   return result;
}

// @brief Send stop order.
// @param orderType OP_BUYSTOP or OP_SELLSTOP
// @param distance from current price in points. Should be calculated 0.0010
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @param expiration Expiration time. If the order is not opened it expire. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::SendStopOrder(int orderType, double lot, double distance, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, datetime expiration = 0)
{
   if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP) {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", OrderTypeToString(orderType)));
      return false;
   }

   double price = 0;
   double sl = 0;
   double tp = 0;
   GetCurrentBidAsk();
   if (orderType == OP_BUYSTOP) 
   {
      price = _ask + distance;
      sl = price - stopLoss;
      tp = price + takeProfit;
   }

   if (orderType == OP_SELLSTOP) {
        price = _bid - distance;
        sl = price + stopLoss;
        tp = price - takeProfit;
   }

   if (stopLoss == 0) {
      sl = 0;
   }

   if (takeProfit == 0) {
      tp = 0;
   }
   
   price = NormalizeDouble(price, _digits);
   sl = NormalizeDouble(sl, _digits);
   tp = NormalizeDouble(tp, _digits);

   bool result = OpenSendInt(orderType, lot, price, sl, tp, NULL /* comment */, magicNumber, expiration);
   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot send stop order."));
   }
   
   return result;
}

// @brief Open buy order direct on the market.
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenBuyOrder(double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL)
{
   bool result = OpenOrder(OP_BUY, lot, stopLoss, takeProfit, magicNumber, comment);

   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open Buy order."));
   }

   return result;
}

// @brief Open Sell order direct on the market.
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenSellOrder(double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0, string comment = NULL)
{
   bool result = OpenOrder(OP_SELL, lot, stopLoss, takeProfit, magicNumber, comment);

   if (!result) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open Sell order."));
   }

   return result;
}

// @brief Open hedge orders buy/sell direct on the market.
// @param baseOrderType OP_BUY or OP_SELL
// @param baseLot Lot for main order.
// @param oppLot Lot for opposite order.
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenHedgeOrders2M(int baseOrderType, double baseLot, double oppLot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0)
{
   if (baseOrderType != OP_BUY && baseOrderType != OP_SELL) {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", baseOrderType));
      return false;
   }

   double buyLot = oppLot;
   double sellLot = oppLot;
   if(baseOrderType == OP_BUY) {
      buyLot = baseLot;
   }
   else {
      sellLot = baseLot;
   }

   // Open buy order
   bool resultBuy = OpenBuyOrder(buyLot, stopLoss, takeProfit, magicNumber);
   if (!resultBuy) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open order."));
   }

   // Open sell order
   bool resultSell = OpenSellOrder(sellLot, stopLoss, takeProfit, magicNumber);
   if (!resultSell)
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open order."));
   }

   return resultBuy && resultSell;
}

// @brief Open order direct on the market and add stop hedge opposite order with lot * 3.
// @param baseOrderType OP_BUY or OP_SELL
// @param lot Lot for main (base) order.
// @param takeProfit in points. Should be calculated 0.0010. StopLoss will be takeProfit * 2.
// @param magicNumberBase Magic number for base order. Default 0.
// @param magicNumberOpp Magic number for opposite order. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenHedgeOrder1To2(int orderType, double lot, double takeProfit, int magicNumberBase = 0, int magicNumberOpp = 0)
{
   if (orderType != OP_BUY && orderType != OP_SELL) 
   {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", orderType));
      return false;
   }

   double stopLoss = takeProfit * 2;

   // Open base order
   bool resultBase = OpenOrder(orderType, lot, stopLoss, takeProfit, magicNumberBase);
   if (!resultBase) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open base order."));
   }

   int oppOrderType = orderType == OP_BUY ? OP_SELLSTOP : OP_BUYSTOP;
   double oppLot = lot * 3;
   double distance = takeProfit;
   double oppStopLoss = takeProfit * 2;
   double oppTakeProfit = takeProfit;
   
   bool resultOpposite = SendStopOrder(oppOrderType, oppLot, distance, oppStopLoss, oppTakeProfit, magicNumberOpp);
   if (!resultBase) 
   {
		_log.Error(StringConcatenate(__FUNCTION__, " cannot open opposite order."));
   }
   
   return resultBase && resultOpposite;
}

// @brief Open hedge order buy or sell and stop opposite order.
// @param orderType OP_BUY or OP_SELL
// @param baseLot Lot for main order.
// @param oppLot Lot for opposite order.
// @param oppOrdDistace Send stop order (opposite) on this distance.
// @param stopLoss in points. Should be calculated 0.0010
// @param takeProfit in points. Should be calculated 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @param oppOrderExp When the opposite order expiraired.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenHedgeOrders1M1S(int baseOrderType, double baseLot, double oppLot, double oppOrdDistace, double stopLoss = 0, 
      double takeProfit = 0, int magicNumber = 0, datetime oppOrderExp = 0)
{
   if (baseOrderType != OP_BUY && baseOrderType != OP_SELL) {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", baseOrderType));
      return false;
   }

   bool resultBuy = false;
   bool resultSell = false;
   // Open buy order.
   if (baseOrderType == OP_BUY) 
   {
      resultBuy = OpenBuyOrder(baseLot, stopLoss, takeProfit, magicNumber);
      if (!resultBuy) 
      {
         _log.Error(StringConcatenate(__FUNCTION__, " cannot open Buy order."));
      }
      
      // Send SellStop order
      resultSell = SendSellStopOrder(oppLot, oppOrdDistace, stopLoss, takeProfit, magicNumber, oppOrderExp);
      if (!resultSell) 
      {
         _log.Error(StringConcatenate(__FUNCTION__, " cannot send SellStop order."));
      }
   }
   else
   {
      resultSell = OpenSellOrder(baseLot, stopLoss, takeProfit, magicNumber);
      if (!resultSell) 
      {
         _log.Error(StringConcatenate(__FUNCTION__, " cannot open Sell order."));
      }
      
      // Send BuyStop order
      resultBuy = SendBuyStopOrder(oppLot, oppOrdDistace, stopLoss, takeProfit, magicNumber, oppOrderExp);
      if (!resultBuy) 
      {
         _log.Error(StringConcatenate(__FUNCTION__, " cannot send BuyStop order."));
      }
   }
   
   return resultBuy && resultSell;
}

// @brief Modifying Stop Loss for an Opened order. Stop loss distance is in points.
// @param ticketId current modified order ticket.
// @param orderType OP_BUY or OP_SELL
// @param stopLoss Stop loss distance in points.
// @param expiration Order expirations time.
// @return true if the order is modified, otherwise false.
bool PSMarket::ModifyOpenedOrderSL(int ticketId, int orderType, int stopLoss, datetime expiration = 0, bool trailingInLoss = true)
{
   GetCurrentBidAsk();
   double sl = -1;
   if (orderType == OP_BUY) {
      sl = _bid - (stopLoss * _points);
   }

   if (orderType == OP_SELL) {
      sl = _ask + (stopLoss * _points);
   }

   return ModifyOpenedOrderSLInt(ticketId, orderType, sl, expiration, trailingInLoss);
}

bool PSMarket::ModifyOpenedOrderSLInt(int ticketId, int orderType, double stopLoss, datetime expiration = 0, bool trailingInLoss = true)
{
   double orderStopLoss = NormalizeDouble(OrderStopLoss(), _digits);

	if (!trailingInLoss) {
      if (OrderProfit() < 0) {
		   return true;
      }
	}

   stopLoss = NormalizeDouble(stopLoss, _digits);

	if (orderType == OP_BUY && orderStopLoss > stopLoss) {
		return true;
	}

	if (orderType == OP_SELL && orderStopLoss < stopLoss) {
		return true;
	}

   return ModifyOpenedOrderInt(ticketId, orderType, stopLoss, -1, expiration);
}

bool PSMarket::ModifyOpenedOrderInt(int ticketId, int orderType, double stopLoss = -1, double takeProfit = -1, datetime expiration = 0)
{
   const double price = 0;
   GetCurrentBidAsk();

   if (stopLoss == -1) {
      stopLoss = OrderStopLoss();
   }
   stopLoss = NormalizeDouble(stopLoss, _digits);

   if (takeProfit == -1) {
      takeProfit = OrderTakeProfit();
   }
   takeProfit = NormalizeDouble(takeProfit, _digits);

   if (stopLoss != 0) {
      if (orderType == OP_BUY && stopLoss >= _bid) {
         LogError(StringConcatenate(__FUNCTION__, " Can not modify buy order. Ticket# ", ticketId, ". StopLoss: ", stopLoss, " is greater than Bid: ", _bid));
         return false;
      }

      if (orderType == OP_SELL && stopLoss <= _ask) {
         LogError(StringConcatenate(__FUNCTION__, " Can not modify sell order. Ticket# ", ticketId, ". StopLoss: ", stopLoss, " is lower than Ask: ", _ask));
         return false;
      }
   }

   bool result = OrderModify(ticketId, price, stopLoss, takeProfit, expiration, OrderTypeToColor(orderType, ModifyOperation));

   if(!result)
   {
      LogError(StringConcatenate(__FUNCTION__, " Failed to modify order with ticket# ", ticketId));

      return false;
   }

   return result;
}

bool PSMarket::OpenSendInt(int orderType, double lot, double price, double stopLoss = 0, double takeProfit = 0, 
   string commentOrder = NULL, int magicNumber = 0, datetime expiration = 0)
{
    // Check is there free money.
    if (orderType == OP_BUY || orderType == OP_SELL) {
      if((AccountFreeMarginCheck(_symbol, orderType, lot) <= 0) || (GetLastError() == 134))
      {
            LogError(StringConcatenate(__FUNCTION__, " Not enough money to send ", OrderTypeToString(orderType), " order."));
         
         return false;
      }
    }

   int ticket = OrderSend(_symbol, orderType, lot, price, _slippage, stopLoss, takeProfit, commentOrder, magicNumber, expiration, OrderTypeToColor(orderType, OpenOperation));
   
   if(ticket == -1)
   {
      LogError(StringConcatenate(__FUNCTION__, " Failed to send ", OrderTypeToString(orderType), " order"));

      return false;
   }

   return true;
}

// @brief Modifying Stop Loss for an Opened order. Stop loss distance is in points.
// @param orderType Order types.
// @param operationType Type of operation.
// @return color. Colour with witch marks operation.
color PSMarket::OrderTypeToColor(int orderType, OperationType operationType)
{
   if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) 
   {
      if (operationType == OpenOperation) {
         return clrBlue;
      }

      if (operationType == CloseOperation) {
         return clrDeepSkyBlue;
      }

      if (operationType == ModifyOperation) {
         return clrDarkOrange;
      }
   }
   
   if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) 
   {
      if (operationType == OpenOperation) {
         return clrRed;
      }

      if (operationType == CloseOperation) {
         return clrMagenta;
      }

      if (operationType == ModifyOperation) {
         return clrGold;
      }
   }

   return clrWhite;
}

string PSMarket::OrderTypeToString(int orderType)
{
   string result = NULL;
   switch (orderType)
   {
      case OP_BUY : result = "Buy"; break;
      case OP_SELL : result = "Sell"; break;
      case OP_BUYLIMIT : result = "BuyLimit"; break;
      case OP_SELLLIMIT : result = "SellLimit"; break;
      case OP_BUYSTOP : result = "BuyStop"; break;
      case OP_SELLSTOP : result = "SellStop"; break;
   
      default: result = "Unknown"; break;
   }
   
   return result;
}

void PSMarket::LogError(string message)
{
      int error = GetLastError();

      _lastError = StringConcatenate(message, " Error code = ", error, ", ",ErrorDescription(error), ".");

      _log.Error(_lastError);
}

void PSMarket::GetCurrentBidAsk()
{
   _bid = MarketInfo(_symbol, MODE_BID); 
   _ask = MarketInfo(_symbol, MODE_ASK); 
}

/*
double Lots(int risk)
  {
   double lot=MathCeil(AccountFreeMargin()*risk/1000)/100;
   if(lot<MarketInfo(Symbol(),MODE_MINLOT))
      lot=MarketInfo(Symbol(),MODE_MINLOT);
   if(lot>MarketInfo(Symbol(),MODE_MAXLOT))
      lot=MarketInfo(Symbol(),MODE_MAXLOT);

   return(lot);
  }
*/

double PSMarket::PointsToPips(double points)
{
   return points * ((_digits == 5 || _digits == 3) ? 10 : 1);
}

double PSMarket::GetLotPerRisk(int riskPercent, int stopLoss, int orderType)
{
   return GetLotPerRisk(riskPercent, stopLoss * _points, orderType);
}

double PSMarket::GetLotPerRisk(int riskPercent, double stopLoss, int orderType)
{
   double risk = riskPercent / 100.0;
   double account = MathMin(AccountBalance(), AccountFreeMargin());
   // Maximum risk in dial.
   double riskAmount = account * risk;
 
   double minLot = MarketInfo(_symbol, MODE_MINLOT);
   double sl = PointsToPips(stopLoss);
   // Number of ticks from start to stop.
   if (sl <= 0) {
      return minLot;
   }
   
   double tickSize = sl / MarketInfo(_symbol, MODE_TICKSIZE);
   double tickValue = tickSize * MarketInfo(_symbol, MODE_TICKVALUE);
   // Amount lots
   double lots = riskAmount / tickValue;

   // Check lot size
   double maxLot = MarketInfo(_symbol, MODE_MAXLOT);
   if (lots > maxLot)
   {
      lots = maxLot;
   }

   if (lots < minLot)
   {
      lots = minLot;
   }
   
   // Normalize lots.
   int digits = 0;
   double lotStep = MarketInfo(_symbol, MODE_LOTSTEP);
   if (lotStep >= 1) // 1
   {
      digits = 0;
   }
   else
   {
      if (lotStep >= 0.1) // 0.1
      {
         digits = 1;  
      }
      else // 0.01
      {
         digits = 2;
      }
   }

   lots = NormalizeDouble(lots, digits);

   //Print(StringConcatenate("GetLotPerRisk SL: ", stopLoss, " lots:", lots));

   return lots;
}

double PSMarket::GetAtr()
{
	const int atrPeriod = 14;

	double bar1 = NormalizeDouble(iATR(_symbol, _period, atrPeriod, 1), _digits);

	return bar1;
}

double PSMarket::GetStdDev()
{
	const int IndPeriod = 20;
	const int IndShift = 0;
	const int IndMethod = MODE_SMA;
	const int IndPrice = PRICE_CLOSE;

	double bar1 = NormalizeDouble(iStdDev(_symbol, _period, IndPeriod, IndShift, IndMethod, IndPrice, 1), _digits);

	return bar1;
}

double PSMarket::GetMfi()
{
	const int IndPeriod = 14;

	double bar1 = NormalizeDouble(iMFI(_symbol, _period, IndPeriod, 1), _digits);

	return bar1;
}