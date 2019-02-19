//+==================================================================+
//|                                                      5c_OsMA.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+==================================================================+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- отрисовка индикатора в отдельном окне
#property  indicator_separate_window
//---- количество индикаторных буфферов
#property  indicator_buffers 5
//---- цвет индикатора  
#property  indicator_color1  Lime
#property  indicator_color2  Blue
#property  indicator_color3  Red
#property  indicator_color4  Magenta
#property  indicator_color5  Silver
//---- ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА
extern int FastEMA=12;
extern int SlowEMA=26;
extern int SignalSMA=9;
//---- iиндикаторные буферы
double     IndBuffer1[];
double     IndBuffer2[];
double     IndBuffer3[];
double     IndBuffer4[];
double     IndBuffer5[];
double     OsmaBuffer[];
double     MacdBuffer[];
double     SignalBuffer[];
//---- константы
int  MinBarM, MinBarS, MinBarO;
//+==================================================================+
//| OsMA indicator initialization function                           |
//+==================================================================+
int init()
  {
//---- определение стиля исполнения графика
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexStyle(4,DRAW_HISTOGRAM);
//---- Установка формата точности отображения индикатора
   IndicatorDigits(Digits+2);
//---- 8 индикаторных буферов использованы для счёта
   IndicatorBuffers(8);
//---- 8 индикаторных буферов использованы для счёта
   SetIndexBuffer(0,IndBuffer1);
   SetIndexBuffer(1,IndBuffer2);
   SetIndexBuffer(2,IndBuffer3);
   SetIndexBuffer(3,IndBuffer4);
   SetIndexBuffer(4,IndBuffer5);
   SetIndexBuffer(5,OsmaBuffer);
   SetIndexBuffer(6,MacdBuffer);
   SetIndexBuffer(7,SignalBuffer);
//---- имя для окон данных и лэйба для субъокон
   IndicatorShortName("OsMA("+FastEMA+","+SlowEMA+","+SignalSMA+")");
//---- инициализация констант   
   MinBarM = MathMax(FastEMA, SlowEMA);
   MinBarS = MinBarM + SignalSMA;
//----
   int DrawBegin = MinBarS + 1;
   SetIndexDrawBegin(0, DrawBegin);
   SetIndexDrawBegin(1, DrawBegin);
   SetIndexDrawBegin(2, DrawBegin);
   SetIndexDrawBegin(3, DrawBegin);
   SetIndexDrawBegin(4, DrawBegin);
//---- завершение инициализации
   return(0);
  }
//+==================================================================+
//| Moving Average of Oscillator                                     |
//+==================================================================+
int start()
  {
//---- проверка количества баров на достаточность для расчёта
   if (Bars - 1 < MinBarS)
                      return(0);
//---- Введение переменных с плавающей точкой 
   double OSMA, dOSMA;
//---- Введение целых переменных и получение уже подсчитанных баров
   int MaxBarM, MaxBarS, bar, limit, counted_bars=IndicatorCounted();
//---- проверка на возможные ошибки
   if (counted_bars < 0)
                   return(-1);
//---- последний подсчитанный бар должен быть пересчитан 
   if (counted_bars > 0)
                  counted_bars--;
//---- определение номера самого старого бара,
           // начиная с которого будет произедён пересчёт всех баров 
   MaxBarM = Bars - MinBarM - 1;
   MaxBarS = MaxBarM - MinBarM;
//---- определение номера самого старого бара, 
          // начиная с которого будет произедён пересчёт новых баров 
   limit = Bars-counted_bars-1; 
//----    
   if (limit > MaxBarM)
              limit = MaxBarM;
//---- расчёт MACD буфера
   for(bar = limit; bar >= 0; bar--)
      MacdBuffer[bar] =
            iMA(NULL, 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, bar)
                  -iMA(NULL, 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, bar);
                  
   if (limit > MaxBarS)
              limit = MaxBarS;                        
//---- расчёт буфера сигнальной линии MACD
   for(bar = limit; bar >= 0; bar--)
      SignalBuffer[bar] =
              iMAOnArray(MacdBuffer, Bars, SignalSMA, 0, MODE_SMA, bar);
      
//---- расчёт OSMA буфера
   for(bar = limit; bar >= 0; bar--)
                 OsmaBuffer[bar] = MacdBuffer[bar] - SignalBuffer[bar];
                 
   MaxBarS--;
   if (limit > MaxBarS)
              limit = MaxBarS;   
//---- расчёт индикаторных трёхцветных буферов
   for(bar = limit; bar >= 0; bar--)
    {
      OSMA = OsmaBuffer[bar];
      dOSMA = OSMA - OsmaBuffer[bar + 1];
      //----
      IndBuffer1[bar] = 0.0;
      IndBuffer2[bar] = 0.0;
      IndBuffer3[bar] = 0.0;
      IndBuffer4[bar] = 0.0;
      IndBuffer5[bar] = 0.0;
      //----
      if(OSMA>0)
        {
          if (dOSMA > 0)
                IndBuffer1[bar] = OSMA;
          if (dOSMA < 0)
                IndBuffer2[bar] = OSMA;
        }
      if(OSMA<0)
        {
          if (dOSMA < 0)
                IndBuffer3[bar] = OSMA;
          if (dOSMA > 0)
                IndBuffer4[bar] = OSMA;
        }
      if(OSMA==0)
        {
          IndBuffer5[bar] = OSMA;
        }
    }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

