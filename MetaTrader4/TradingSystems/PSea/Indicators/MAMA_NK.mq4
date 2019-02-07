
/*
Version  November 28, 2007

ƒл€  работы  индикатора  следует  положить файлы 
PriceSeries.mqh 
в папку (директорию): MetaTrader\experts\include\
MAMA_NK.mq4
Heiken Ashi#.mq4
в папку (директорию): MetaTrader\indicators\
*/
//+X================================================================X+
//|                                                      MAMA_NK.mq4 |
//|                    MAMA skript:                      John Ehlers |
//|                    MQL4 CODE: Copyright © 2007, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+X================================================================X+
#property link  "farria@mail.redcom.ru/"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 2 
//---- цвета индикатора
#property indicator_color1 Blue
#property indicator_color2 Red
//---- толщина индикаторных линий
#property indicator_width1 1
#property indicator_width2 1
//---- ¬’ќƒЌџ≈ ѕј–јћ≈“–џ »Ќƒ» ј“ќ–ј 
extern double FastLimit = 0.5;
extern double SlowLimit = 0.05;
extern int IPC = 4;/* ¬ыбор цен, по которым производитс€ расчЄт индикатора 
(0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 
7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 
11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 
14-Heiken Ashi Close, 15-Heiken Ashi Open0.) */
//---- индикаторные буфферы
double FAMA[];
double MAMA[];
//+X================================================================X+
//| ќбъ€вление функции PriceSeries                                   |
//| ќбъ€вление функции PriceSeriesAlert                              | 
//+X================================================================X+
#include <PriceSeries.mqh>
//+X================================================================X+
//| SetEmulationIndexBuffer() function                               |
//+X================================================================X+
void SetEmulationIndexBuffer(double & Array[])
//----+
  {
    if (ArraySize(Array)<Bars)
                          ArraySetAsSeries(Array, false);
    ArrayResize(Array, Bars);
    ArraySetAsSeries(Array, true);
  }
//----+
//+X================================================================X+
//| CountVelue() function                                            |
//+X================================================================X+
double CountVelue(double & Array1[], double & Array2[], int Bar)
//----+
  {
    double Resalt = 
       (0.0962 * Array1[Bar + 0]
          + 0.5769 * Array1[Bar + 2] 
              - 0.5769 * Array1[Bar + 4] 
                  - 0.0962 * Array1[Bar + 6])
                      * (0.075 * Array2[Bar + 1] + 0.54);
    return(Resalt);
  }
//----+
//+X================================================================X+
//| SmoothVelue() function                                           |
//+X================================================================X+
double SmoothVelue(double & Array[], int Bar)
//----+
  {
    double Resalt = 0.2 * Array[Bar] + 0.8 * Array[Bar + 1];
    return(Resalt);
  }
//----+
//+X================================================================X+
//| MAMA initialization function                                     |
//+X================================================================X+
int init()
//----+
  {
//---- —тиль исполнени€ графика
    SetIndexStyle(0, DRAW_LINE);
    SetIndexStyle(1, DRAW_LINE);
//---- 2 индикаторных буффера использованы дл€ счЄта
    SetIndexBuffer(0, FAMA);                                     
    SetIndexBuffer(1, MAMA);
//---- установка значений индикатора, которые не будут видимы на графике
    SetIndexEmptyValue(0,0.0);
    SetIndexEmptyValue(1,0.0);
//---- им€ дл€ окон данных и лэйба дл€ субъокон
    IndicatorShortName("#MAMA");
    SetIndexLabel(0, "#FAMA");
    SetIndexLabel(1, "#MAMA");
//---- установка номера бара, 
                  //начина€ с которого будет отрисовыватьс€ индикатор 
    SetIndexDrawBegin(0, 50);
    SetIndexDrawBegin(1, 50);
//---- установка алертов на недопустимые значени€ входных параметров
    PriceSeriesAlert(IPC);
//---- завершение инициализации
    return(0);
  }
//----+
//+X================================================================X+
//|    MAMA iteration function                                       |
//+X================================================================X+
int start()
//----+
  {
    int BARS=Bars;    
    //---- проверка количества баров на достаточность дл€ расчЄта
    if(BARS <= 7) 
            return(0);
    //---- введение переменных пам€ти  
    static double smooth[1], detrender[1], Q1[1], I1[1], I2[1];
    static double Q2[1], jI[1], jQ[1], Re[1], Im[1], period[1], Phase[1];
    //---- Ёћ”Ћя÷»я »Ќƒ» ј“ќ–Ќџ’ Ѕ”‘≈–ќ¬
    SetEmulationIndexBuffer(smooth   );
    SetEmulationIndexBuffer(detrender);
    SetEmulationIndexBuffer(period   );
    SetEmulationIndexBuffer(Phase    );
    SetEmulationIndexBuffer(Q1       );
    SetEmulationIndexBuffer(I1       );
    SetEmulationIndexBuffer(I2       );
    SetEmulationIndexBuffer(Q2       );
    SetEmulationIndexBuffer(jI       );
    SetEmulationIndexBuffer(jQ       );
    SetEmulationIndexBuffer(Re       );
    SetEmulationIndexBuffer(Im       );
    //----+ ¬ведение целых переменных и получение уже посчитанных баров
    int MaxBar, limit, bar, counted_bars=IndicatorCounted();
    //---- проверка на возможные ошибки
    if (counted_bars<0)
                   return(-1);
    //---- последний посчитанный бар должен быть пересчитан
    if (counted_bars>0) 
                  counted_bars--;
    //----+ ¬ведение переменных с плавающей точкой
    double DeltaPhase, alpha; 
    //---- определение номера самого старого бара, 
             //начина€ с которого будет произведЄн полный пересчЄт всех баров 
    MaxBar=BARS - 1 - 7;
    //---- определение номера самого старого бара, 
             //начина€ с которого будет произедЄн пересчЄт только новых баров 
    limit = BARS - 1 - counted_bars;
    //---- инициализаци€ нул€
    if(limit>=MaxBar)
     {
       for(bar = BARS - 1; bar > MaxBar; bar--) 
         {
           MAMA[bar] = 0.0;
           FAMA[bar] = 0.0;
           smooth[bar] = 0.0;
           detrender[bar] = 0.0;
           period[bar] = 0.0;
           Phase[bar] = 0.0;
           Q1[bar] = 0.0;
           I1[bar] = 0.0;
           I2[bar] = 0.0;
           Q2[bar] = 0.0;
           jI[bar] = 0.0;
           jQ[bar] = 0.0;
           Re[bar] = 0.0;
           Im[bar] = 0.0;
         }
       limit = MaxBar;
       MAMA[MaxBar+1]=PriceSeries(IPC, MaxBar + 1);
       FAMA[MaxBar+1]=PriceSeries(IPC, MaxBar + 1);
     }
    //----
    for (bar = limit; bar >= 0; bar--)
      {
	     smooth[bar] = (4 * PriceSeries(IPC, bar + 0) 
	                    + 3 * PriceSeries(IPC, bar + 1) 
	                      + 2 * PriceSeries(IPC, bar + 2)
	                        + 1 * PriceSeries(IPC, bar + 3)) / 10.0;
        //---+
        detrender[bar] = CountVelue(smooth, period, bar);
        //---+ Compute InPhase and Quadrature components
        Q1[bar] = CountVelue(detrender, period, bar);
	     I1[bar] = detrender[bar + 3];
        ///---+ Advance the phase of I1 and Q1 by 90 degrees
	     jI[bar] = CountVelue(I1, I1, bar);
	     jQ[bar] = CountVelue(Q1, Q1, bar);
        //---+ Phasor addition for 3 bar averaging
        I2[bar] = I1[bar] - jQ[bar];
	     Q2[bar] = Q1[bar] - jI[bar];
	     //---+ Smooth the I and Q components 
	                         //before applying the discriminator
	     I2[bar] = SmoothVelue(I2, bar);
        Q2[bar] = SmoothVelue(Q2, bar);
        //---+ Homodyne Discriminator
    	  Re[bar] = I2[bar] * I2[bar + 1] + Q2[bar] * Q2[bar + 1];
    	  Im[bar] = I2[bar] * Q2[bar + 1] - Q2[bar] * I2[bar + 1];
        //---+ 
        Re[bar] = SmoothVelue(Re,bar);
        Im[bar] = SmoothVelue(Im,bar);
        //---+
        if (Im[bar] != 0 && Re[bar] != 0)
                         period[bar] = 
                            6.285714 / MathArctan(Im[bar] / Re[bar]);
        //---+
        if (period[bar] > 1.50 * period[bar + 1]) 
                                period[bar] = 1.50 * period[bar + 1];
        if (period[bar] < 0.67 * period[bar + 1]) 
                                period[bar] = 0.67 * period[bar + 1];
        if (period[bar] < 6.00 * period[bar + 1]) 
                                period[bar] = 6.00;      
        if (period[bar] > 50.0 * period[bar + 1]) 
                                period[bar] = 50.0;
        //---+
        period[bar] = 0.2 * period[bar] + 0.8 * period[bar + 1];
        //---+
        if (I1[bar] != 0)
                 Phase[bar] = 
                      57.27272987 * MathArctan(Q1[bar] / I1[bar]);
        //---+
        DeltaPhase = Phase[bar + 1] - Phase[bar];
        if (DeltaPhase < 1)
                      DeltaPhase = 1.0;
        //---+
        alpha = FastLimit / DeltaPhase;
        if (alpha < SlowLimit)
                      alpha = SlowLimit;
        //---+
        MAMA[bar] = alpha * PriceSeries(IPC, bar) 
                          + (1.0 - alpha) * MAMA[bar + 1];
        FAMA[bar] = 0.5 * alpha * MAMA[bar] 
                        + (1.0 - 0.5 * alpha) * FAMA[bar + 1];    
      }
    return(0);
  }
//----+
//+X================================================================X+

/*MAMA EasyLanguage Code
Inputs:	Price((H+L)/2),
		FastLimit(.5),
		SlowLimit(.05);

Vars:	Smooth(0), 
	Detrender(0), 
	I1(0), 
	Q1(0), 
	jI(0),
	jQ(0),
	I2(0),
	Q2(0),
	Re(0), 
	Im(0), 
	Period(0),
	SmoothPeriod(0),
	Phase(0),
	DeltaPhase(0),
	alpha(0),
	MAMA(0),
   FAMA(0);
					
If CurrentBar > 5 then begin
	Smooth = (4*Price + 3*Price[1] + 2*Price[2] + Price[3]) / 10;	
	Detrender = (.0962*Smooth + .5769*Smooth[2] - .5769*Smooth[4] - .0962*Smooth[6])*(.075*Period[1] + .54);

	{Compute InPhase and Quadrature components}
	Q1 = (.0962*Detrender + .5769*Detrender[2] - .5769*Detrender[4] - .0962*Detrender[6])*(.075*Period[1] + .54);
      I1 = Detrender[3];

	{Advance the phase of I1 and Q1 by 90 degrees}
	jI = (.0962*I1 + .5769*I1[2] - .5769*I1[4] - .0962*I1[6])*(.075*Period[1] + .54);
	jQ = (.0962*Q1 + .5769*Q1[2] - .5769*Q1[4] - .0962*Q1[6])*(.075*Period[1] + .54);

	{Phasor addition for 3 bar averaging)}
	I2 = I1 - jQ;
	Q2 = Q1 + jI;

	{Smooth the I and Q components before applying the discriminator}
	I2 = .2*I2 + .8*I2[1];
	Q2 = .2*Q2 + .8*Q2[1];

	{Homodyne Discriminator}
	Re = I2*I2[1] + Q2*Q2[1];
	Im = I2*Q2[1] - Q2*I2[1];
	Re = .2*Re + .8*Re[1];
	Im = .2*Im + .8*Im[1];
	If Im <> 0 and Re <> 0 then Period = 360/ArcTangent(Im/Re);
	If Period > 1.5*Period[1] then Period = 1.5*Period[1];
	If Period < .67*Period[1] then Period = .67*Period[1];
	If Period < 6 then Period = 6;
	If Period > 50 then Period = 50;
	Period = .2*Period + .8*Period[1];
	SmoothPeriod = .33*Period + .67*SmoothPeriod[1];

	If I1 <> 0 then Phase = (ArcTangent(Q1 / I1));
	DeltaPhase = Phase[1] - Phase;
	If DeltaPhase < 1 then DeltaPhase = 1;
	alpha = FastLimit / DeltaPhase;
	If alpha < SlowLimit then alpha = SlowLimit;
	MAMA = alpha*Price + (1 - alpha)*MAMA[1];
   FAMA = .5*alpha*MAMA + (1 - .5*alpha)*FAMA[1];
	
	Plot1(MAMA, "MAMA");
   Plot2(FAMA, "FAMA");

End;
*/

