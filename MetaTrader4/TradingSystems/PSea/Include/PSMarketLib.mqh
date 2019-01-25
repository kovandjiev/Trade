//+------------------------------------------------------------------+
//|                                                  PSMarketLib.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#define TimeFrameCount 9

int TimeFrames[TimeFrameCount] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1 };

bool IsTimeFrameValid(int period)
{
   for(int i = 0; i < TimeFrameCount; i++)
   {
      
      if (TimeFrames[i] == period) 
      {
         return true;
      }
   }

   return false;
}

// Get previous TF.
// period: finded period from which gets previos.
// periodDown: it should be form 1 to 8;
// Example: period = PERIOD_H1, result: PERIOD_M30.
int GetPreviousTimeFrame(int period, short periodDown = 1)
{
   for(int i = 0; i < TimeFrameCount; i++)
   {
      
      if (TimeFrames[i] == period) 
      {
         // Check if first period found or previous period lover than 0.
         if (i == 0 || (i - periodDown < 0)) {
            return -1;
         }
         
         return TimeFrames[i - 1];
      }
   }
   
   return -1;
}

double Lots(int risk)
  {
   double lot=MathCeil(AccountFreeMargin()*risk/1000)/100;
   if(lot<MarketInfo(Symbol(),MODE_MINLOT))
      lot=MarketInfo(Symbol(),MODE_MINLOT);
   if(lot>MarketInfo(Symbol(),MODE_MAXLOT))
      lot=MarketInfo(Symbol(),MODE_MAXLOT);

   return(lot);
  }
  
//--------------------------------------------------------------------
bool GetNecessaryLotsWithRisk(int riskPercent, double sl, double price, double& lots)
{
   //error = LOTS_NORMAL;
   
   double ticks = MathAbs(sl - price) / MarketInfo(Symbol(), MODE_TICKSIZE),  // количество тиков от старта до стопа
      riskAmount = AccountBalance() * riskPercent / 100.0;                    // максимальный убыток от сделки
   lots = riskAmount / (ticks * MarketInfo(Symbol(), MODE_TICKVALUE));     // высчитанное количество лотов
   
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT),
      minLot = MarketInfo(Symbol(), MODE_MINLOT),
      lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
      
   // проверяем допустимость лотов
   if (lots > maxLot)
   {
      //error = LOTS_TOO_BIG;
      lots = 0;
      return(false);
   }
   if (lots < minLot)
   {
      //error = LOTS_TOO_SMALL;
      lots = 0;
      return(false);
   }
   
   // округляем лоты до нужной величины
   int digits;
   if (lotStep >= 1) digits = 0;             // 1
   else  if (lotStep * 10 >= 1) digits = 1;  // 0.1
         else digits = 2;                    // 0.01
   lots = NormalizeDouble(lots, digits);

      return(true);
}

/*
int _Ticket = 0, _Type = 0; double _Lots = 0.0, _OpenPrice = 0.0, _StopLoss = 0.0; 
double _TakeProfit = 0.0; datetime _OpenTime = -1; double _Profit = 0.0, _Swap = 0.0; 
double _Commission = 0.0; string _Comment = ""; datetime _Expiration = -1; 

void OneOrderInit( int magic ) 
{ 
int _GetLastError, _OrdersTotal = OrdersTotal(); 

_Ticket = 0; _Type = 0; _Lots = 0.0; _OpenPrice = 0.0; _StopLoss = 0.0; 
_TakeProfit = 0.0; _OpenTime = -1; _Profit = 0.0; _Swap = 0.0; 
_Commission = 0.0; _Comment = ""; _Expiration = -1; 

for ( int z = _OrdersTotal - 1; z >= 0; z -- ) 
{ 
if ( !OrderSelect( z, SELECT_BY_POS ) ) 
{ 
_GetLastError = GetLastError(); 
Print( "OrderSelect( ", z, ", SELECT_BY_POS ) - Error #", _GetLastError ); 
continue; 
} 
if ( OrderMagicNumber() == magic && OrderSymbol() == Symbol() ) 
{ 
_Ticket	= OrderTicket(); 
_Type	= OrderType(); 
_Lots	= NormalizeDouble( OrderLots(), 1 ); 
_OpenPrice	= NormalizeDouble( OrderOpenPrice(), Digits ); 
_StopLoss	= NormalizeDouble( OrderStopLoss(), Digits ); 
_TakeProfit	= NormalizeDouble( OrderTakeProfit(), Digits ); 
_OpenTime	= OrderOpenTime(); 
_Profit	= NormalizeDouble( OrderProfit(), 2 ); 
_Swap	= NormalizeDouble( OrderSwap(), 2 ); 
_Commission	= NormalizeDouble( OrderCommission(), 2 ); 
_Comment	= OrderComment(); 
_Expiration	= OrderExpiration(); 
return(0); 
} 
} 
} 
*/

// Finding opaned order.
//  If open order is found return order ticket.
//  if none orders return -1.
int GetFirstOpenOrder(int magicNumber)
 {
   int ordersTotal = OrdersTotal();
   string symbol = _Symbol;
   
   for(int i=0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol()==symbol) && OrderMagicNumber()==magicNumber)
         {
            return(OrderTicket());
         }
      }
   }
   
   return -1;
}
