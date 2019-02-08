//+X----------------------------------------------------------------x+
// Edited Nikolay Kositsin  2008.05.20 E-mail: farria@mail.redcom.ru |
//+X----------------------------------------------------------------x+
//+X================================================================X+
//|                                              StepMA_Stoch_NK.mq4 |
//|                          Copyright © 2005,  TrendLaboratory Ltd. |
//|                                       E-mail: igorad2004@list.ru |
//+X================================================================X+
#property copyright "Copyright © 2005,  TrendLaboratory Ltd."
#property link "http://www.forex-instruments.info"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов
#property indicator_buffers 2
//---- цвета индикатора
#property indicator_color1 Gold
#property indicator_color2 BlueViolet
//---- определение нижнего и верхнего 
            //значения отдельного окна индикатора
#property indicator_minimum 0
#property indicator_maximum 1
//---- ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА 
extern int    PeriodWATR = 10; 
extern double Kwatr = 1.0000; 
extern int    HighLow = 0; 
//---- индикаторные буферы
double LineMinBuffer[]; 
double LineMidBuffer[]; 
//+X================================================================X+
//| StepMA_3D_NK indicator initialization function                   |
//+X================================================================X+
  int init()
  {
//---- установка стиля изображения индикатора 
   SetIndexStyle(0, DRAW_LINE, STYLE_DASHDOTDOT, 1); 
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2); 
//---- определение буферов для подсчёта  
   SetIndexBuffer(0, LineMinBuffer); 
   SetIndexBuffer(1, LineMidBuffer); 
//---- Установка формата точности (количество знаков после 
          //десятичной точки) для визуализации значений индикатора 
   IndicatorDigits(Digits); 
//---- name for DataWindow and indicator subwindow label
   string short_name="StepMA Stoch("
                  + PeriodWATR + ", " + Kwatr + ", " + HighLow + ")"; 
   IndicatorShortName(short_name); 
   SetIndexLabel(0, "StepMA Stoch 1"); 
   SetIndexLabel(1, "StepMA Stoch 2"); 
//---- установка номера бара, 
                //начиная с которого будет отрисовываться индикатор 
   SetIndexDrawBegin(0, PeriodWATR); 
   SetIndexDrawBegin(1, PeriodWATR); 
//---- завершение инициализации
   return(0); 
  }
//+X================================================================X+
//| StepMA_3D_NK                                                     |
//+X================================================================X+
int start()
  {
   //---- Проверка количества баров на достаточность 
                                //для дальнейшего расчёта
   if (Bars - 1 < PeriodWATR)
                        return(0);
   //----
   static int      TrendMid_, time2;
   static int      TrendMin_, TrendMax_;
   //----
   static double   WATRmax_, WATRmin_;
   static double   SminMin1_, SmaxMin1_;  
   static double   SminMax1_, SmaxMax1_; 
   static double   SminMid1_, SmaxMid1_;
   //----
   int      counted_bars, Tnew;
   int      iii, bar, MaxBar, limit;
   int      TrendMin, TrendMax, TrendMid;
   int      StepSizeMin, StepSizeMax, StepSizeMid; 
   //----
   double   close, high, low;  
   double   WATRmax, WATRmin;
   double   SumRange, dK, WATR0;
   double   SizeMin, SizeMax, SizeMid;
   double   SizeMin2, SizeMax2, SizeMid2, point;
   double   SminMin0, SmaxMin0, SminMin1, SmaxMin1;  
   double   SminMax0, SmaxMax0, SminMax1, SmaxMax1; 
   double   SminMid0, SmaxMid0, SminMid1, SmaxMid1;
   double   Stoch1, Stoch2, bsmin, bsmax;
   double   linemin, linemax, linemid;  
   //----Получение уже посчитанных баров
   counted_bars = IndicatorCounted();
   //---- проверка на возможные ошибки
   if (counted_bars < 0)
                 return(-1);
   //---- последний посчитанный бар должен быть пересчитан 
   if (counted_bars > 0) 
                counted_bars--;
   //---- определение номера самого старого бара, 
          // начиная с которого будет произедён пересчёт новых баров
   limit = Bars - counted_bars - 1;
   //---- определение номера самого старого бара, 
          // начиная с которого будет произедён пересчёт всех баров 
   MaxBar = Bars - 1 - PeriodWATR; 
   //----	
   if (limit > MaxBar) 
                limit = MaxBar;
                
   //+---+ восстановление значений переменных +------------------------+
   Tnew = Time[limit + 1];
   if (limit < MaxBar)
    if (Tnew == time2)
     {
      WATRmax = WATRmax_;
	   WATRmin = WATRmin_;
	   //----
      SminMin1 = SminMin1_; 
	   SmaxMin1 = SmaxMin1_; 
	   //----
	   SminMax1 = SminMax1_; 
	   SmaxMax1 = SmaxMax1_; 
	   //----
	   SminMid1 = SminMid1_; 
	   SmaxMid1 = SmaxMid1_;
	   //----
	   TrendMin = TrendMin_;
	   TrendMax = TrendMax_;
	   TrendMid = TrendMid_;
     }
   else 
     {
      if (Tnew>time2)
           Print("Ошибка восстановления переменных!!! Tnew>time2");
      else Print("Ошибка восстановления переменных!!! Tnew<time2");
      Print("Будет произведён пересчёт индикатора на всех барах!");
      return(-1);  
     }
   //+---+ +-------------------------------------------------------------+
   
   for(bar = limit; bar >= 0; bar--)
   {
    //+---+ Сохранение значений переменных 
     if (bar == 1)
       {
         WATRmax_ = WATRmax;
	      WATRmin_ = WATRmin;
	      //----
         SminMin1_ = SminMin1; 
	      SmaxMin1_ = SmaxMin1; 
	      //----
	      SminMax1_ = SminMax1; 
	      SmaxMax1_ = SmaxMax1; 
	      //----
	      SminMid1_ = SminMid1; 
	      SmaxMid1_ = SmaxMid1; 
	      //----
	      TrendMin_ = TrendMin;
	      TrendMax_ = TrendMax;
	      TrendMid_ = TrendMid;
	      //----
         time2 = Time[2];
       }
     //+---+
     //----
     SumRange = 0.0;
     //----
	  for (iii = PeriodWATR - 1; iii >= 0; iii--)
	    { 
         dK = 1.0 + 1.0 * (PeriodWATR - iii) / PeriodWATR; 
         SumRange += dK * MathAbs(High[bar + iii] - Low[bar + iii]); 
       }
     //----  
	  WATR0 = SumRange / PeriodWATR; 
	  //----
	  WATRmax = MathMax(WATR0, WATRmax);
	  if (bar == MaxBar) 
	             WATRmin = WATR0;
	  //----            
	  WATRmin = MathMin(WATR0, WATRmin); 
	  //----
	  point = Point;
	  //----
	  StepSizeMin = MathRound(Kwatr * WATRmin / point); 
	  StepSizeMax = MathRound(Kwatr * WATRmax / point); 
     StepSizeMid = MathRound(Kwatr * 0.5 * (WATRmax + WATRmin) / point); 
     //----
     SizeMin = StepSizeMin * point;
     SizeMax = StepSizeMax * point;
     SizeMid = StepSizeMid * point;
     //----
     SizeMin2 = 2 * SizeMin;
     SizeMax2 = 2 * SizeMax;
     SizeMid2 = 2 * SizeMid;
     //----
     low = Low[bar];
     high = High[bar];
     close = Close[bar];
	  //----	
	  if (HighLow > 0)
	   {
	    SmaxMin0 = low + SizeMin2; 
	    SminMin0 = high - SizeMin2; 
	    //----
	    SmaxMax0 = low + SizeMax2; 
	    SminMax0 = high - SizeMax2; 
	    //----
	    SmaxMid0 =  low + SizeMid2; 
	    SminMid0 =  high - SizeMid2; 
	    //----
	    if(close > SmaxMin1) TrendMin = 1;  
	    if(close < SminMin1) TrendMin = -1; 
	    //----
	    if(close > SmaxMax1) TrendMax = 1;  
	    if(close < SminMax1) TrendMax = -1; 
	    //----
	    if(close > SmaxMid1) TrendMid = 1;  
	    if(close < SminMid1) TrendMid = -1; 
	   }
	  //----
	  if (HighLow == 0)
	   {
	    SmaxMin0 = close + SizeMin2; 
	    SminMin0 = close - SizeMin2; 
	    //----
	    SmaxMax0 = close + SizeMax2; 
	    SminMax0 = close - SizeMax2; 
	    //----
	    SmaxMid0 = close + SizeMid2; 
	    SminMid0 = close - SizeMid2; 
	    //----
	    if(close > SmaxMin1) 
	                    TrendMin = 1;  
	    if(close < SminMin1)
	                    TrendMin = -1; 
	    //----
	    if(close > SmaxMax1) 
	                    TrendMax = 1;  
	    if(close < SminMax1) 
	                    TrendMax = -1; 
	    //----
	    if(close > SmaxMid1) 
	                    TrendMid = 1;  
	    if(close < SminMid1) 
	                    TrendMid = -1; 
	   }
	  //----	
	  if(TrendMin > 0 && SminMin0 < SminMin1) 
	                               SminMin0 = SminMin1; 
	  if(TrendMin < 0 && SmaxMin0 > SmaxMin1) 
	                               SmaxMin0 = SmaxMin1; 
		
	  if(TrendMax > 0 && SminMax0 < SminMax1) 
	                               SminMax0 = SminMax1; 
	  if(TrendMax < 0 && SmaxMax0 > SmaxMax1) 
	                               SmaxMax0 = SmaxMax1; 
	  
	  if(TrendMid > 0 && SminMid0 < SminMid1) 
	                               SminMid0 = SminMid1; 
	  if(TrendMid < 0 && SmaxMid0 > SmaxMid1) 
	                               SmaxMid0 = SmaxMid1;
	  //----                             
	  if (TrendMin > 0) 
	            linemin = SminMin0 + SizeMin; 
	  if (TrendMin < 0) 
	            linemin = SmaxMin0 - SizeMin; 
	  
	  if (TrendMax > 0) 
	            linemax = SminMax0 + SizeMax; 
	  if (TrendMax < 0) 
	            linemax = SmaxMax0 - SizeMax; 
	  
	  if (TrendMid > 0) 
	            linemid = SminMid0 + SizeMid; 
	  if (TrendMid < 0) 
	            linemid = SmaxMid0 - SizeMid; 
	  //----
	  bsmin = linemax - SizeMax; 
	  bsmax = linemax + SizeMax; 
	  //----
	  Stoch1 = (linemin - bsmin) / (bsmax - bsmin); 
	  Stoch2 = (linemid - bsmin) / (bsmax - bsmin); 
	  //----
	  LineMinBuffer[bar] = Stoch1; 
	  LineMidBuffer[bar] = Stoch2; 
	  //----	  
	  SminMin1 = SminMin0; 
	  SmaxMin1 = SmaxMin0; 
	  //----
	  SminMax1 = SminMax0; 
	  SmaxMax1 = SmaxMax0; 
	  //----
	  SminMid1 = SminMid0; 
	  SmaxMid1 = SmaxMid0; 
	 }
	return(0); 	
 }
//+---+ +X----------------------------------------------------------X+