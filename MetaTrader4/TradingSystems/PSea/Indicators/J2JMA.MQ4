/*
Для  работы  индикатора  следует  положить файлы 
JJMASeries.mqh 
PriceSeries.mqh 
в папку (директорию): MetaTrader\experts\include\
Heiken Ashi#.mq4
в папку (директорию): MetaTrader\indicators\
*/
//+------------------------------------------------------------------+  
//|                                                        J2JMA.mq4 | 
//|                       JMA code: Copyright © 2005, Jurik Research | 
//|                                          http://www.jurikres.com | 
//|    MQL4 JJMASeries+J2JMA: Copyright © 2006,     Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+  
#property copyright "Copyright © 2006, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 1 
//---- цвет индикатора
#property indicator_color1 Magenta 
//---- ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА -----------------------------------------------------------------------------------------------------+
extern int Length1 = 5; // глубина  первого сглаживания 
extern int Length2 = 5; // глубина  второго сглаживания 
extern int Phase1  = 100; // параметр первого сглаживания, изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса; 
extern int Phase2  = 100; // параметр второго сглаживания, изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса; 
extern int Shift   = 0; // cдвиг индикатора вдоль оси времени 
extern int Input_Price_Customs = 0;/* Выбор цен, по которым производится расчёт индикатора 
(0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW,
11-Heiken Ashi Low, 12-Heiken Ashi High,  13-Heiken Ashi Open, 14-Heiken Ashi Close.) */
//---- ----------------------------------------------------------------------------------------------------------------------------------+
//---- индикаторные буферы
double J2JMA[];
//---- переменные с плавающей точкой  
double Temp_Series;
//+------------------------------------------------------------------+  
//----+ Введение функции JJMASeries 
//----+ Введение функции JJMASeriesResize 
//----+ Введение функции JJMASeriesAlert  
//----+ Введение функции JMA_ErrDescr  
#include <JJMASeries.mqh> 
//+------------------------------------------------------------------+  
//----+ Введение функции PriceSeries
//----+ Введение функции PriceSeriesAlert 
#include <PriceSeries.mqh>
//+------------------------------------------------------------------+     
//| J2JMA indicator initialization function                          | 
//+------------------------------------------------------------------+  
int init() 
{  
//---- определение стиля исполнения графика
SetIndexStyle (0,DRAW_LINE); 
//---- 1 индикаторный буфер использован для счёта
SetIndexBuffer(0,J2JMA);
//---- горизонтальный сдвиг индикаторной линии 
SetIndexShift (0, Shift);  
//---- установка значений индикатора, которые не будут видимы на графике
SetIndexEmptyValue(0,0); 
//---- имя для окон данных и лэйба для субъокон 
IndicatorShortName ("J2JMA( Length1="+Length1+", Phase1="+Phase1+", Length2="+Length2+", Phase2="+Phase2+", Shift="+Shift+")"); 
SetIndexLabel (0, "J2JMA"); 
//---- Установка формата точности отображения индикатора
IndicatorDigits(Digits);
//----+ Изменение размеров буферных переменных функции JJMASeries, nJMAnumber=2(Два обращения к функции JJMASeries)
if (JJMASeriesResize(2)!=2)return(-1);
//---- установка алертов на недопустимые значения внешних переменных
JJMASeriesAlert (0,"Length1",Length1);
JJMASeriesAlert (0,"Length2",Length2);
JJMASeriesAlert (1,"Phase1", Phase1 );
JJMASeriesAlert (1,"Phase2", Phase2 );
PriceSeriesAlert(Input_Price_Customs);
//---- завершение инициализации
return(0); 
} 
//+------------------------------------------------------------------+  
//| J2JMA iteration function                                         | 
//+------------------------------------------------------------------+  
int start() 
{ 
//---- Проверка количества баров на достаточность для дальнейшего расчёта
if (Bars-1<61)return(0);
//----+ Введение целых переменных и получение уже подсчитанных баров
int reset,MaxBar1,MaxBar2,counted_bars=IndicatorCounted();
//---- проверка на возможные ошибки
if (counted_bars<0)return(-1);
//---- последний подсчитанный бар должен быть пересчитан 
//---- (без этого пересчёта для counted_bars функция JJMASeries будет работать некорректно!!!)
if (counted_bars>0) counted_bars--;
//---- определение номера самого старого бара, начиная с которого будет произедён пересчёт новых баров
int limit=Bars-counted_bars-1; MaxBar1=Bars-1; MaxBar2=MaxBar1-30;

//----+ ОСНОВНОЙ ЦИКЛ ВЫЧИСЛЕНИЯ ИНДИКАТОРА 
for(int bar=limit;bar>=0;bar--)
{
//----+ Обращение к функции PriceSeries для получения входной цены Series
Temp_Series=PriceSeries(Input_Price_Customs, bar);
//+----------------------------------------------------------------------------+ 
//----+ Два обращения к функции JJMASeries за номерами 0, 1. Параметры nJMA.Phase и nJMA.Length не меняются на каждом баре (nJMA.din=0)
//(Во втором  обращении параметр nJMA.MaxBar  уменьшен на 30  т. к. это повторное JMA сглаживание)
//+----------------------------------------------------------------------------+   
Temp_Series=JJMASeries(0,0,MaxBar1,limit,Phase1,Length1,Temp_Series,bar,reset);
//----+ проверка на отсутствие ошибки в предыдущей операции
if(reset!=0)return(-1);
//+----------------------------------------------------------------------------+ 
Temp_Series=JJMASeries(1,0,MaxBar2,limit,Phase2,Length2,Temp_Series,bar,reset);
//----+ проверка на отсутствие ошибки в предыдущей операции
if(reset!=0)return(-1);
//+----------------------------------------------------------------------------+ 
J2JMA[bar]=Temp_Series;
}
//---- завершение вычислений значений индикатора
return(0); 
} 
//+---------------------------------------------------------------+

