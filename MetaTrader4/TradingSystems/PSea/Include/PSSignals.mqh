//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property library
#property strict

bool bWasBuy = false;
bool bWasSell = false;

// PK
//#include <../Indicators/Laguerre.mq4>
// Install Laguerre.mq4 in /Indicators/Laguerre.mq4

bool CheckSignalId(int signalId)
{
	return signalId >= 1 && signalId <= 24;
}

int CheckSignal(int signalID, bool entry)
{
	switch (signalID)
	{
		// -14.23
		case 1:	return (BlackSys(entry)); break;
		// -223.42
		case 2:		return (BorChan(entry)); break;
		// -108.26
		case 3:		return (Collaps(entry)); break;
		// -91.82
		case 4:		return (CspLine(entry)); break;
		// -129.04
		case 5:			return (DifMA(entry)); break;
		// -20.52
		case 6:		return (DifMAS(entry)); break;
		// -6.92
		case 7:		return (Envelop(entry)); break;
		// -140.07
		case 8:	return (Envelop2(entry)); break;
		// -269.81
		case 9:	return (Korablik(entry)); break;
		// -680.47
		case 10:	return (Krivetka(entry)); break;
		// -91.17
		case 11:		return (Laguer(entry)); break;
		// 16.68
		case 12:			return (Macd(entry)); break;
		// 13.16
		case 13:			return (Macd2(entry)); break;
		// -236.64
		case 14:		return (MA(entry)); break;
		// 20.04
		case 15:	return (MA2(entry)); break;
		// -129.76
		case 16:	return (MA3(entry)); break;
		// -315.13
		case 17:			return (Sidus(entry)); break;
		// -65.94
		case 18:	return (SidusSafe(entry)); break;
		// -64.26
		case 19:	return (SidusSinc(entry)); break;
		// H1 55.64  H4 -125.89
		case 20:		return (Vegas1H(entry)); break;
		// H4 -175.61  H1 -69.54
		case 21:		return (Vegas4H(entry)); break;
		// H1 -76.58   H4 52.67
		case 22:				return (Wpr(entry)); break;
		// -445.50
		case 23:			return (Wpr2(entry)); break;
		// -26.66
		case 24: return CCI(); break;   
		//case 9:			return (Force(entry)); break;

		default: 
		{
		   Print("Invalid signal ID: ", signalID);
		   return (-1);
		}
	}
}

// PK
/*
int DayMA(bool bEntry)
{
	int i;
	datetime time;
	double dp=0.0;
	double buy, sell;
	double hi=0.0, lo=0.0, avg=0.0, op=0.0, cl=0.0;
	double do_=0.0, dc=0.0;
	if (TimeHour(TimeCurrent())<=20) 
	{ bWasBuy = false; bWasSell = false; return (-1);}
	
	if (TimeMinute(TimeCurrent())==21 && (!bWasBuy || !bWasSell))
	{
		hi = iHigh(NULL, PERIOD_D1, 0); lo = iLow(NULL, PERIOD_D1, 0); avg = (hi+lo)/2;
		op = iOpen(NULL, PERIOD_D1, 0); cl = iClose(NULL, PERIOD_D1, 0);
		do_ = MathAbs(op-avg); dc = MathAbs(cl-avg); 
		
		time = StrToTime("7:00");
		i = iBarShift(NULL, 0, time);

		if (bEntry)   //для открытия
		{ 	
			if (Ask>buy && !bWasBuy) {bWasBuy = true; return (OP_BUY);}
 			if (Bid<sell && !bWasSell) {bWasSell = true; return (OP_SELL);}
		}	
		else
		{
			if (Ask>buy) return (OP_SELL);
 			if (Bid<sell) return (OP_BUY);
 		}
	}
	return (-1); //нет сигнала
}
*/
int Korablik(bool bEntry)
{
	double ao0, ac0, ao1, ac1, sar, adxp, adxn, al1, al2, al3;
	
	adxp = iADX(NULL, 0, 14, PRICE_CLOSE, MODE_PLUSDI, 0);
	adxn = iADX(NULL, 0, 14, PRICE_CLOSE, MODE_MINUSDI, 0);
	ao0=iAO(NULL, 0, 0); ao1=iAO(NULL, 0, 1);
	ac0=iAC(NULL, 0, 0); ac1=iAC(NULL, 0, 1);
	sar = iSAR(NULL, 0, 0.02, 0.2, 0);
	al1 = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, 0);
	al2 = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, 0);
	al3 = iAlligator(NULL, 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, 0);
	
	if (bEntry)   //для открытия
	{ 	
		if (ao0>ao1 && ac0>ac1 && Open[0]>=al1 && al1>al2 && al2>al3 && Low[0]>=sar && adxp>adxn) return (OP_BUY);
		if (ao0<ao1 && ac0<ac1 && Open[0]<=al1 && al1<al2 && al2<al3 && High[0]<=sar && adxp<adxn) return (OP_SELL);
	}	
	else
	{
		if (ao0>ao1 && ac0>ac1 && Open[0]>=al1 && al1>al2 && al2>al3 && Low[0]>=sar && adxp>adxn) return (OP_SELL);
		if (ao0<ao1 && ac0<ac1 && Open[0]<=al1 && al1<al2 && al2<al3 && High[0]<=sar && adxp<adxn) return (OP_BUY);
	}
	return(-1);
}

int Laguer(bool bEntry)
{
	double L1, L2;
  
	L1=iCustom(NULL, 0, "Laguerre", 0.7, 100, 0, 1);
	L2=iCustom(NULL, 0, "Laguerre", 0.7, 100, 0, 2);
  
	if (bEntry)   //для открытия
	{ 	
		if (L1>L2 && L2==0) return (OP_BUY);
   	if (L1<L2 && L2==1) return (OP_SELL);
	}	
	else
	{
		if (L1>L2 && L2==0) return (OP_SELL);
   	if (L1<L2 && L2==1) return (OP_BUY);
	}
	return(-1);
}

// Indicator not found.
// int Force(bool bEntry)
// {
// 	double f1 = iCustom(NULL, 0, "Sem Force", 10, 3, 50, MODE_SMA, PRICE_CLOSE, 3, 1);
// 	double f2 = iCustom(NULL, 0, "Sem Force", 10, 3, 50, MODE_SMA, PRICE_CLOSE, 3, 2);
	
// 	if (bEntry) 
// 	{
// 		if (f1<f2 && f2==100) return (OP_SELL);// Если достигли верхней границы канала
// 		if (f1>f2 && f2==-100) return (OP_BUY);// Если достигли нижней границы канала
// 	}
// 	else
// 	{
// 		if (f1<f2 && f2==100) return (OP_BUY);// Если достигли верхней границы канала
// 		if (f1>f2 && f2==-100) return (OP_SELL);// Если достигли нижней границы канала
// 	}
// 	return(-1);
// }

int BorChan(bool bEntry)
{
	ObjectDelete("GC_Channel1"); ObjectDelete("GC_Channel2");
	int pos, pos2, Depth=12;
	int i=Depth;
	double h1 = 0.0, h2 = 0.0, l1 = 0.0, l2 = 0.0; 
	int xh1=0, xh2=0, xl1=0, xl2=0;
	double pl=0.0, ph=0.0;
	while(i<Bars-1 && xh1==0)
	{
		pos = iHighest(NULL,0,MODE_HIGH,2*Depth+1,i-Depth);	pos2 = iHighest(NULL,0,MODE_HIGH,2*Depth+1,pos-Depth); 
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (High[pos]==High[pos-1]) 
		      pos = pos-1; 
		   h1=High[pos];  
		   xh1=pos;
		}
		i++;
	}
	i = xh1+2*Depth;
	while(i<Bars-1 && xh2==0)
	{
		pos = iHighest(NULL,0,MODE_HIGH,2*Depth+1,i-Depth);	pos2 = iHighest(NULL,0,MODE_HIGH,2*Depth+1,pos-Depth); 
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (High[pos]==High[pos-1]) 
		      pos = pos-1; 
		   h2=High[pos];  
		   xh2=pos;
		}
		i++;
	}
	i = Depth;
   while(i<Bars-1 && xl1==0)
	{
   	pos = iLowest(NULL,0,MODE_LOW,2*Depth+1,i-Depth);	pos2 = iLowest(NULL,0,MODE_LOW,2*Depth+1,pos-Depth); 
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (Low[pos]==Low[pos-1]) 
		      pos = pos-1; 
		   l1=Low[pos]; 
		   xl1 = pos;
		}
   	i++;
	}
	
	i = xl1+2*Depth;
	while(i<Bars-1 && xl2==0)
	{
		pos = iLowest(NULL,0,MODE_LOW,2*Depth+1,i-Depth);	pos2 = iLowest(NULL,0,MODE_LOW,2*Depth+1,pos-Depth); 
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (Low[pos]==Low[pos-1]) 
		      pos = pos-1; 
		   l2=Low[pos]; 
		   xl2 = pos; 
		}
		i++;
	}
	//если сначала нашли низ
	if (xh1>xl1) { h2=h1-(l1-l2); xh2 = xh1+(xl2-xl1); } else { l2=l1-(h1-h2); xl2 = xl1+(xh2-xh1); }
	pl = l2+xl2*(l1-l2)/(xl2-xl1); ph = h2+xh2*(l1-l2)/(xl2-xl1);

   ObjectCreate("GC_Channel1", OBJ_TREND, 0, Time[xh2], h2, Time[xh1], h1);
   ObjectCreate("GC_Channel2", OBJ_TREND, 0, Time[xl2], l2, Time[xl1], l1);

//	double MA0=0.0, MA1=0.0;
//	MA0=iMA(NULL,0,16,0,MODE_EMA,PRICE_CLOSE,0);	MA1=iMA(NULL,0,28,0,MODE_EMA,PRICE_CLOSE,0);

	if (bEntry) 
	{
		if (Bid>=ph-2*Point && Bid<=ph+2*Point) return (OP_SELL);// Если достигли верхней границы канала
		if (Ask<=pl+2*Point && Ask>=pl-2*Point) return (OP_BUY);// Если достигли нижней границы канала
	}
	else
	{
		if (Bid>=ph-2*Point && Bid<=ph+2*Point) return (OP_BUY);// Если достигли верхней границы канала 
		if (Ask<=pl+2*Point && Ask>=pl-2*Point) return (OP_SELL);// Если достигли нижней границы канала
	}
	return(-1);
}

//PK
/*int Kis(bool bEntry)
{
	int i;
	datetime time;
	double dp=0.0;
	double buy, sell;
	double hi=0.0, lo=0.0, avg=0.0, op=0.0, cl=0.0;
	double do_=0.0, dc=0.0;
	if (TimeHour(TimeCurrent())<=20) 
	{ bWasBuy = false; bWasSell = false; return (-1);}
	
	if (TimeMinute(TimeCurrent())==21 && (!bWasBuy || !bWasSell))
	{
		hi = iHigh(NULL, PERIOD_D1, 0); lo = iLow(NULL, PERIOD_D1, 0); avg = (hi+lo)/2;
		op = iOpen(NULL, PERIOD_D1, 0); cl = iClose(NULL, PERIOD_D1, 0);
		do_ = MathAbs(op-avg); dc = MathAbs(cl-avg); 
		
		time = StrToTime("7:00");
		i = iBarShift(NULL, 0, time);

		if (bEntry)   //для открытия
		{ 	
			if (Ask>buy && !bWasBuy) {bWasBuy = true; return (OP_BUY);}
 			if (Bid<sell && !bWasSell) {bWasSell = true; return (OP_SELL);}
		}	
		else
		{
			if (Ask>buy) return (OP_SELL);
 			if (Bid<sell) return (OP_BUY);
 		}
	}
   return (-1); //нет сигнала
}
*/
int Krivetka(bool bEntry)
{
	double zz0=0.0, zz1=0.0;
	int i=0;
	while (i<Bars-1 && zz0==0.0)
	{ zz0 = iCustom(NULL, 0, "ZigZag", 20, 10, 3, 0, i); i++;	}

	while (i<Bars-1 && zz1==0.0)
	{ zz1 = iCustom(NULL, 0, "ZigZag", 20, 10, 3, 0, i); i++;	}

	if (bEntry)   //для открытия
	{ 	
		if (zz0>zz1)	return (OP_BUY);
		if (zz0<zz1)	return (OP_SELL);
	}	
	else
	{
		if (zz0>zz1)	return (OP_SELL);
		if (zz0<zz1)	return (OP_BUY);
	}
   return (-1); //нет сигнала
}

int MA3(bool bEntry)
{
	int w4 = 4, w8=8, d5=5, d20=20;
	double w4_0, w4_1, w8_0, w8_1, d5_0, d5_1, d5_2, d20_0, d20_1;
	w4_0 = iMA(NULL, PERIOD_W1, w4, 0, MODE_SMA, PRICE_CLOSE, 0);
	w4_1 = iMA(NULL, PERIOD_W1, w4, 0, MODE_SMA, PRICE_CLOSE, 1);
	w8_0 = iMA(NULL, PERIOD_W1, w8, 0, MODE_SMA, PRICE_CLOSE, 0);
	w8_1 = iMA(NULL, PERIOD_W1, w8, 0, MODE_SMA, PRICE_CLOSE, 1);
	
	d5_0 = iMA(NULL, PERIOD_D1, d5, 0, MODE_SMA, PRICE_CLOSE, 0);
	d5_1 = iMA(NULL, PERIOD_D1, d5, 0, MODE_SMA, PRICE_CLOSE, 1);
	d5_2 = iMA(NULL, PERIOD_D1, d5, 0, MODE_SMA, PRICE_CLOSE, 2);
	d20_0 = iMA(NULL, PERIOD_D1, d20, 0, MODE_SMA, PRICE_CLOSE, 0);
	d20_1 = iMA(NULL, PERIOD_D1, d20, 0, MODE_SMA, PRICE_CLOSE, 1);
	if (bEntry)   //для открытия
	{ 	
		if (w4_0>w4_1 && w8_0>w8_1 && d20_0>d20_1 && d5_0>d5_1 && d5_2>d5_1) return (OP_BUY);
		if (w4_0<w4_1 && w8_0<w8_1 && d20_0<d20_1 && d5_0<d5_1 && d5_2<d5_1) return (OP_SELL);
	}	
	else
	{
		if (w4_0>w4_1 && w8_0>w8_1 && d20_0>d20_1 && d5_0>d5_1 && d5_2>d5_1) return (OP_SELL);
		if (w4_0<w4_1 && w8_0<w8_1 && d20_0<d20_1 && d5_0<d5_1 && d5_2<d5_1) return (OP_BUY);
	}
   return (-1); //нет сигнала
}

int CspLine(bool bEntry)
{
	int i;
	datetime time;
	double dp=0.0, mid=0.0, atr=0.0;
	double buy, sell;
	if (TimeHour(TimeCurrent())<7) { bWasBuy = false; bWasSell = false;}
	if (TimeHour(TimeCurrent())>7 && (!bWasBuy || !bWasSell))
	{
		time = StrToTime("7:00");
		i = iBarShift(NULL, 0, time);
		atr = iATR(NULL, 0, 15, i);
		dp = MathAbs(Open[i]-Close[i]);
		mid = (Open[i]+Close[i])/2;
		if (dp>50)	{ buy = Close[i]+atr; sell = Close[i]-atr;}
		else { buy = mid+atr; sell= mid-atr; }

		if (bEntry)   //для открытия
		{ 	
			if (Ask>buy && !bWasBuy) {bWasBuy = true; return (OP_BUY);}
 			if (Bid<sell && !bWasSell) {bWasSell = true; return (OP_SELL);}
		}	
		else
		{
			if (Ask>buy) return (OP_SELL);
 			if (Bid<sell) return (OP_BUY);
 		}
	}
   return (-1); //нет сигнала
}

int Collaps(bool bEntry)
{
	int maPeriod=120;
	double Laguerre;
	double cci;
	double MA0, MA1;
  
	Laguerre=iCustom(NULL, 0, "Laguerre", 0.7, 100, 0, 1);
	cci=iCCI(NULL, 0, 14, PRICE_CLOSE, 0);
	MA0=iMA(NULL,0,maPeriod,0,MODE_EMA,PRICE_MEDIAN,0);
	MA1=iMA(NULL,0,maPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
  
	if (bEntry)   //для открытия
	{ 	
		if (Laguerre==0 && MA0>MA1 && cci<-10) return (OP_BUY);
   	if (Laguerre==1 && MA0<MA1 && cci>10) return (OP_SELL);
	}	
	else
	{
		if (Laguerre>0.9) return (OP_BUY);
		if (Laguerre<0.1) return (OP_SELL);
	}
   return (-1); //нет сигнала
}

int Vegas1H(bool bEntry)
{
	int MA=169;
	double Deviation=0.04;
	int Mode=MODE_EMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight

   double envH, envL;
	envH=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	
	int signal = -1; //нет сигнала
	
	if (bEntry)   //для открытия
	{ 	
		if (Bid<envL && High[0]>envH) return (OP_SELL);
		if (Bid>envH && Low[0]<envL) return (OP_BUY);
	}
	else //для закрытия
	{
		if (Bid<envL && High[0]>envH) return (OP_BUY);
		if (Bid>envH && Low[0]<envL) return (OP_SELL);
	}
	
   return (signal);
}

int Envelop2(bool bEntry)
{
	int MA=20;
	double Deviation=0.13;
	int Mode=MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	double maSlow, maFast;
	
   double envH0, envL0;
	envH0=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL0=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_LOWER, 0); 

	maFast=iMA(NULL, 0, MA, 0, Mode, Price, 0); 
	maSlow=iMA(NULL, 0, MA+2, 0, Mode, Price, 0); 
	
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if (Bid<envL0 && maFast>maSlow) return (OP_BUY);
		if (Ask>envH0 && maFast<maSlow) return (OP_SELL);
	}
	else //для закрытия
	{
		if (Bid<envL0 && maFast>=maSlow) return (OP_SELL);
		if (Ask>envH0 && maFast<=maSlow) return (OP_BUY);
	}
   return (-1); //нет сигнала
}

int Envelop(bool bEntry)
{
	int MA=21;
	double Deviation=0.6;
	int Mode=MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	
   double envH0, envL0, m0;
   double envH1, envL1, m1;
	envH0=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL0=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	envH1=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_UPPER, 1); 
	envL1=iEnvelopes(NULL, 0, MA, Mode, 0, Price, Deviation, MODE_LOWER, 1); 

	m0 = (Low[0]+High[0])/2;	m1 = (Low[1]+High[1])/2;
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if (envH0<m0 && envH1<m1) return (OP_SELL);
		if (envL0>m0 && envL1>m1) return (OP_BUY);
	}
	else //для закрытия
	{
		if (envH0<m0 && envH1<m1) return (OP_BUY);
		if (envL0>m0 && envL1>m1) return (OP_SELL);
	}

   return (-1); //нет сигнала
}

int Wpr2(bool bEntry)
{
   int i;
   double wpr0, wpr1;
   int val, period=9;
   double Range;
   int M1=-1,M2=-1;
	bool b;	
   //******************************************************************************
 	Range=0.0;
	for (i=0; i<=period; i++) Range=Range+MathAbs(High[i]-Low[i]);
	Range=Range/(period+1);

	b=false; i=0;
	while (i<period && !b)
	{ if (MathAbs(Open[i]-Close[i+1])>=Range*2.0) b = true; i++; }
	if (b) val=(int)MathFloor(period/3);

	b=false; i=0;
	while (i<period-3 && !b)
	{ if (MathAbs(Close[i+3]-Close[i])>=Range*4.6) b = true; i++;	}
	if (b) val=(int)MathFloor(period/2); else val=period;

	//****************************************************************************************
	
	wpr0=100-MathAbs(iWPR(NULL,0,val,0)); wpr1=100-MathAbs(iWPR(NULL,0,val,1));
   
	if (bEntry)   //для открытия
	{ 	
      if (wpr0>80 && wpr1<80) return (OP_BUY);
      if (wpr0<20 && wpr1>20) return (OP_SELL);
	}
	else //для закрытия
	{
      if (wpr0<20) return (OP_BUY);
      if (wpr0>80) return (OP_SELL);
	}
   return (-1); //нет сигнала
}

int Wpr(bool bEntry)
{
	int     m=20;
   double wpr0, wpr1, wpr2;
//----
	wpr0=iWPR(NULL, 0, m, 0); wpr1=iWPR(NULL, 0, m, 1); wpr2=iWPR(NULL, 0, m, 2); 
		
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if (wpr2> -80 && wpr1< -80 && wpr0>-80) return (OP_BUY);
		if (wpr2< -20 && wpr1> -20 && wpr0<-20) return (OP_SELL);
	}
	else //для закрытия
	{
		if (wpr2> -80 && wpr1< -80 && wpr0>-80) return (OP_SELL);
		if (wpr2< -20 && wpr1> -20 && wpr0<-20) return (OP_BUY);
	}	
   return (-1); //нет сигнала
}

int MA2(bool bEntry)
{
	int PRICE   = PRICE_CLOSE; // метод вычисления средних
	int slowMAPeriod = 300;
	int fastMAPeriod = 30;	 
	double fMa1, fMa0, sMa1, sMa0, sar1, sar0;
	sMa1 = iMA(NULL,0,slowMAPeriod,0,MODE_SMA,PRICE,3);	
	sMa0 = iMA(NULL,0,slowMAPeriod,0,MODE_SMA,PRICE,0);
	fMa1 = iMA(NULL,0,fastMAPeriod,0,MODE_EMA,PRICE,3);	
	fMa0 = iMA(NULL,0,fastMAPeriod,0,MODE_EMA,PRICE,0);
	sar1 = iSAR(NULL,0,0.02,0.2,6);	sar0 = iSAR(NULL,0,0.02,0.2,0);

	if (bEntry)   //для открытия
	{ 	
   	if ((sMa1>fMa1*0.998 && sMa0<fMa0*0.998)&& sar1>Open[6]&&sar0<Open[0]) return (OP_BUY);
   	if ((sMa1<fMa1*0.998 && sMa0>fMa0*0.998)&& sar1<Open[6]&&sar0>Open[0]) return (OP_SELL);
   }
   else
	{
		if (sMa1<fMa1*0.998 && sMa0>fMa0*0.9978) return (OP_BUY);
      if (sMa1>fMa1*0.998 && sMa0<fMa0*0.9978) return (OP_SELL);
   }
   return (-1); //нет сигнала
}
int MA(bool bEntry)
{
	//параметры средних
	int SlowMA=7;
	int FastMA=5;
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних
	int PERIOD     = 0;//PERIOD_H1; // на каком периоде работать

   double sCur, fCur, sPre1, fPre1, sPre2, fPre2;
//----

	sCur=iMA(NULL, PERIOD, SlowMA, 0, MODE_MA, PRICE_MA, 0);
	sPre1=iMA(NULL, PERIOD, SlowMA, 0, MODE_MA, PRICE_MA, 1);
	sPre2=iMA(NULL, PERIOD, SlowMA, 0, MODE_MA, PRICE_MA, 2);
	fCur=iMA(NULL, PERIOD, FastMA, 0, MODE_MA, PRICE_MA, 0);
	fPre1=iMA(NULL, PERIOD, FastMA, 0, MODE_MA, PRICE_MA, 1);
	fPre2=iMA(NULL, PERIOD, FastMA, 0, MODE_MA, PRICE_MA, 2);

	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if (fCur>sCur && fPre1>sPre1 && fPre2<sPre2) return (OP_BUY);
		if (fCur<sCur && fPre1<sPre1 && fPre2>sPre2) return (OP_SELL);
	}
	else //для закрытия
	{
		if (fCur>sCur && fPre1>sPre1 && fPre2<sPre2) return (OP_SELL);
		if (fCur<sCur && fPre1<sPre1 && fPre2>sPre2) return (OP_BUY);
	}
 
   return (-1); //нет сигнала
}

int Macd2(bool bEntry)
{
	int fMA=7;
	int sMA=36;
	int sigMA=7;
	int PRICE = PRICE_CLOSE;
	double Level=0.001;
	
	int i=0;
	double Range, Delta0, Delta1;

	Range = iATR(NULL,0,200,1)*Level;
	Delta0=iMACD(NULL,0,fMA,sMA,sigMA,PRICE,MODE_MAIN,0)-iMACD(NULL, 0 ,fMA,sMA,sigMA,PRICE,MODE_SIGNAL,0);
	Delta1=iMACD(NULL,0,fMA,sMA,sigMA,PRICE,MODE_MAIN,1)-iMACD(NULL, 0 ,fMA,sMA,sigMA,PRICE,MODE_SIGNAL,1);

	if (bEntry)   //для открытия
	{ 	
		if (Delta0>Range && Delta1<Range) return (OP_BUY);
		if (Delta0<-Range && Delta1>-Range) return (OP_SELL);
	}
	else //для закрытия
	{
		if(Delta0<0) return (OP_BUY);
		if(Delta0>0) return (OP_SELL);
	}
   return (-1); //нет сигнала
}

int Macd(bool bEntry)
{
	double MACDOpen=3;
	double MACDClose=2;
	int maPeriod=26;
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних
	int PERIOD     = PERIOD_H1; // на каком периоде работать

	//параметры средних
   double MacdCur, MacdPre, SignalCur;
   double SignalPre, MaCur, MaPre;

//---- получить значение
   MacdCur=iMACD(NULL,0,8,17,9,PRICE_MA,MODE_MAIN,0);
   MacdPre=iMACD(NULL,0,8,17,9,PRICE_MA,MODE_MAIN,1);
   SignalCur=iMACD(NULL,0,8,17,9,PRICE_MA,MODE_SIGNAL,0);
   SignalPre=iMACD(NULL,0,8,17,9,PRICE_MA,MODE_SIGNAL,1);
   MaCur=iMA(NULL,0,maPeriod,0,MODE_MA,PRICE_MA,0);
   MaPre=iMA(NULL,0,maPeriod,0,MODE_MA,PRICE_MA,1);

	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre && MathAbs(MacdCur)>(MACDOpen*Point) && MaCur>MaPre) return (OP_BUY);
		if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre && MacdCur>(MACDOpen*Point) && MaCur<MaPre) return (OP_SELL);
	}
	else //для закрытия
	{	
      if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre && MacdCur>(MACDClose*Point)) return (OP_BUY);
		if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre && MacdCur>(MACDOpen*Point) && MaCur<MaPre) return (OP_BUY);

      if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre && MathAbs(MacdCur)>(MACDClose*Point))  return (OP_SELL);
		if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre && MathAbs(MacdCur)>(MACDOpen*Point) && MaCur>MaPre) return (OP_SELL);
	}
 
   return (-1); //нет сигнала
}

int Sidus(bool bEntry)
{
	//параметры средних
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних
	int PERIOD     = 0; // на каком периоде работать

   double rf, rs, bf, bs;
//---- получить скользящие средние 
   bf=iMA(NULL, PERIOD, MABluFast, 0, MODE_MA, PRICE_MA, 0);
   bs=iMA(NULL, PERIOD, MABluSlow, 0, MODE_MA, PRICE_MA, 0);
   rf=iMA(NULL, PERIOD, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rs=iMA(NULL, PERIOD, MARedSlow, 0, MODE_MA, PRICE_MA, 0);

	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if ((rf>rs) && (bf>bs) && (Ask<=bs))  return (OP_BUY);   
		if ((rf<rs) && (bf<bs) && (Bid>=bs))  return (OP_SELL); 
	}
	else //для закрытия
	{	
		if ((bf<bs) && (bs<rf))  return (OP_BUY); 
		if ((bf>bs) && (bs>rf))  return (OP_SELL);  
	}
 
   return (-1); //нет сигнала
}

int SidusSafe(bool bEntry)
{
	//параметры средних сидуса
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних
	int PERIOD     = 0; // на каком периоде работать

	//параметры RVI
	int RVI_PERIOD  = 100; 

	//параметры Stoch
	int K_PERIOD		= 8; 
	int D_PERIOD		= 5; 
	int SLOW				= 5; 
	int METHOD_STOCH	= MODE_EMA; // метод вычисления средних

   double rf, rs, bf, bs, rvi, rvi_signal, stoch;
//---- получить скользящие средние 
   bf=iMA(NULL, PERIOD, MABluFast, 0, MODE_MA, PRICE_MA, 0);
   bs=iMA(NULL, PERIOD, MABluSlow, 0, MODE_MA, PRICE_MA, 0);
   rf=iMA(NULL, PERIOD, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rs=iMA(NULL, PERIOD, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
   rvi = iRVI(NULL, PERIOD, RVI_PERIOD, MODE_MAIN, 0);
   rvi_signal = iRVI(NULL, PERIOD, RVI_PERIOD, MODE_SIGNAL, 0);
	
	stoch = iStochastic(NULL, PERIOD, K_PERIOD, D_PERIOD, SLOW, METHOD_STOCH, 0, MODE_MAIN, 0);
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if ((rf>rs) && (bf>bs) && (Ask<=bs) && (rvi>=rvi_signal) && (stoch>50))  return (OP_BUY);   
		if ((rf<rs) && (bf<bs) && (Bid>=bs) && (rvi<=rvi_signal) && (stoch<50))  return (OP_SELL); 
	}
	else //для закрытия
	{	
		if ((bf<bs) && (bs<rf))  return (OP_BUY); 
		if ((bf>bs) && (bs>rf))  return (OP_SELL);  
	}
 
   return (-1); //нет сигнала
}

int SidusSinc(bool bEntry)
{
	//параметры 
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_LWMA; // метод вычисления средних
	int PRICE_MA   = PRICE_WEIGHTED; // метод вычисления средних
	int PERIOD     = PERIOD_H1; // на каком периоде работать
	int PERIOD2    = PERIOD_D1; // на каком периоде работать
	int PERIOD3    = PERIOD_M30; // на каком периоде работать
	int PERIOD4    = PERIOD_H4; // на каком периоде работать

   double rh1f, rh1s, rd1f, rd1s, rh4f, rh4s, rm30f, rm30s;
//---- получить скользящие средние 
   rm30f	=iMA(NULL, PERIOD3, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rm30s	=iMA(NULL, PERIOD3, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   rh1f	=iMA(NULL, PERIOD, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rh1s	=iMA(NULL, PERIOD, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   rh4f	=iMA(NULL, PERIOD4, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rh4s	=iMA(NULL, PERIOD4, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   rd1f	=iMA(NULL, PERIOD2, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rd1s	=iMA(NULL, PERIOD2, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
//		if ((rh1f>rh1s) && (rd1f>rd1s) && (rh4f>rh4s) && (Ask<=rh1f-35*Point))  return (OP_BUY); 
//		if ((rh1f<rh1s) && (rd1f<rd1s) && (rh4f<rh4s) && (Bid>=rh1f+35*Point))  return (OP_SELL); 
		if ((rh1f>rh1s) && (rh4f>rh4s) && (rd1f>rd1s) && (rm30f>rm30s) && (Ask<=rh1f-15*Point))  return (OP_BUY);   //для евры
		if ((rh1f<rh1s) && (rh4f<rh4s) && (rd1f<rd1s) && (rm30f<rm30s) && (Bid>=rh1f+15*Point))  return (OP_SELL);  //для евры
	}
	else //для закрытия
	{	
		if (rh1f<rh1s)  return (OP_BUY); 
		if (rh1f>rh1s)  return (OP_SELL);  
	}
 
   return (-1); //нет сигнала
}

int BlackSys(bool bEntry)
{
	//параметры средних
	int MA  			= 20; //  канал 
	int MA_F  		= 17; //  канал 
	int MODE_MA    = MODE_SMA; // метод вычисления средних
	int PRICE_MA   = PRICE_MEDIAN; // метод вычисления средних
	int PERIOD     = PERIOD_H4; // на каком периоде работать

	//параметры RSI
	int RSI_PERIOD  = 3; 

   double rs, rf, rsi, rsiPre;
//---- получить скользящие средние 
   rs=iMA(NULL, PERIOD, MA, 0, MODE_MA, PRICE_MA, 0);
   rf=iMA(NULL, PERIOD, MA_F, 0, MODE_MA, PRICE_MA, 0);
   
   rsi = iRSI(NULL, PERIOD, RSI_PERIOD, PRICE_WEIGHTED, 0);
   rsiPre = iRSI(NULL, PERIOD, RSI_PERIOD, PRICE_WEIGHTED, 1);
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if ((rsiPre<30) && (rsi>30) && (Ask<rs) && (rf>rs))  return (OP_BUY);   
		if ((rsiPre>70) && (rsi<70) && (Bid>rs) && (rf<rs))  return (OP_SELL);   
	}
	else //для закрытия
	{	
		if ((rsiPre<30) && (rsi>30) && (Ask<rs) && (rf>rs))  return (OP_SELL);  
		if ((rsiPre>70) && (rsi<70) && (Bid>rs) && (rf<rs))  return (OP_BUY); 
	}
 
   return (-1); //нет сигнала
}

int Vegas4H(bool bEntry)
{
	//параметры средних
	int       MA5=5;//для недельного
	int       MA21=21;//для недельного
	int       MA8=8;//для 1Н и 4Н
	int       MA55=55;//для 1Н и 4Н
	int       RiskModel=1;

   double w5Pre, w21Pre, w5Cur, w21Cur, h, h11Pre, h11Cur, h12Pre, h12Cur, dwCur, dwPre;
//---- получить скользящие средние 
	w5Cur=iMA(NULL, PERIOD_W1, MA5, 0, MODE_SMA, PRICE_MEDIAN, 0);
	w21Cur=iMA(NULL, PERIOD_W1, MA21, 0, MODE_EMA, PRICE_MEDIAN, 0);
	w5Pre=iMA(NULL, PERIOD_W1, MA5, 0, MODE_SMA, PRICE_MEDIAN, 1);
	w21Pre=iMA(NULL, PERIOD_W1, MA21, 0, MODE_EMA, PRICE_MEDIAN, 1);

	dwCur = w5Cur-w21Cur; dwPre = w5Pre-w21Pre;
	
	h11Cur=iMA(NULL, PERIOD_H1, MA8, 0, MODE_SMA, PRICE_CLOSE, 0);
	h12Cur=iMA(NULL, PERIOD_H1, MA55, 0, MODE_SMA, PRICE_MEDIAN, 0);
	h11Pre=iMA(NULL, PERIOD_H1, MA8, 0, MODE_SMA, PRICE_CLOSE, 1);
	h12Pre=iMA(NULL, PERIOD_H1, MA55, 0, MODE_SMA, PRICE_MEDIAN, 1);

	h=iMA(NULL, PERIOD_H4, MA55, 0, MODE_SMA, PRICE_MEDIAN, 0);
	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{ 	
		if ((h12Cur>h11Cur) && (h12Pre>h11Pre) && (h11Cur>h11Pre) 
				&& (w5Cur>w21Cur) && (w5Pre>w21Pre) && (dwCur>dwPre)) return (OP_BUY);   
		if ((h12Cur<h11Cur) && (h12Pre<h11Pre) && (h11Cur<h11Pre) 
				&& (w5Cur<w21Cur) && (w5Pre<w21Pre) && (dwCur<dwPre)) return (OP_SELL);   
	}
	else //для закрытия
	{	
		if ((h11Cur<h11Pre) || (Bid>h+89*Point)) return (OP_BUY);   
		if ((h11Cur>h11Pre) || (Bid<h-89*Point)) return (OP_SELL);   
	}
 
   return (-1); //нет сигнала
}

int DifMA(bool bEntry)
{
	//параметры средних 
	int MA5=5;
	int MA7=7;
	int MA25=25;
	int MA27=27;
	int MA55=55;
	int MA57=57;
	int MODE_MA=MODE_EMA;
	int PRICE=PRICE_MEDIAN;
	int PERIOD=PERIOD_H1;

   double dxCurA, dxPreA, dxCurB, dxPreB, dxCurC, dxPreC;
	double dx2, dx1, x, x0, x1, xx1, xx2;
	x = iMA(NULL, PERIOD, MA5, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA5, 0, MODE_MA, PRICE, 1); dx1 = x-x0; xx1 = x0;
	x = iMA(NULL, PERIOD, MA7, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA7, 0, MODE_MA, PRICE, 1); dx2 = x-x0; xx2 = x0;
	dxCurA = 100*(dx1-dx2);
	x1 = iMA(NULL, PERIOD, MA5, 0, MODE_MA, PRICE, 2); dx1 = xx1-x1;
	x1 = iMA(NULL, PERIOD, MA7, 0, MODE_MA, PRICE, 2); dx2 = xx2-x1;
	dxPreA = 100*(dx1-dx2);

	x = iMA(NULL, PERIOD, MA25, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA25, 0, MODE_MA, PRICE, 1); dx1 = x-x0; xx1 = x0;
	x = iMA(NULL, PERIOD, MA27, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA27, 0, MODE_MA, PRICE, 1); dx2 = x-x0; xx2 = x0;
	dxCurB = 100*(dx1-dx2);
	x1 = iMA(NULL, PERIOD, MA25, 0, MODE_MA, PRICE, 2); dx1 = xx1-x1;
	x1 = iMA(NULL, PERIOD, MA27, 0, MODE_MA, PRICE, 2); dx2 = xx2-x1;
	dxPreB = 100*(dx1-dx2);

	x = iMA(NULL, PERIOD, MA55, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA55, 0, MODE_MA, PRICE, 1); dx1 = x-x0; xx1 = x0;
	x = iMA(NULL, PERIOD, MA57, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA57, 0, MODE_MA, PRICE, 1); dx2 = x-x0; xx2 = x0;
	dxCurC = 100*(dx1-dx2);
	x1 = iMA(NULL, PERIOD, MA55, 0, MODE_MA, PRICE, 2); dx1 = xx1-x1;
	x1 = iMA(NULL, PERIOD, MA57, 0, MODE_MA, PRICE, 2); dx2 = xx2-x1;
	dxPreC = 100*(dx1-dx2);

	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{
		if ((dxCurA>dxPreA) && (dxCurB>dxPreB) && (dxCurC>dxPreC))
			if (((dxCurB>0) && (dxPreB<0)) && ((dxCurC>0) && (dxPreC<0)))	return (OP_BUY);
		if ((dxCurA<dxPreA) && (dxCurB<dxPreB) && (dxCurC<dxPreC))
			if (((dxCurB<0) && (dxPreB>0)) && ((dxCurC<0) && (dxPreC>0)))	return (OP_SELL);
	}
	else //для закрытия
	{	
		if ((dxCurA>dxPreA) || (dxCurB>dxPreB) || (dxCurC>dxPreC))
			if (((dxCurB>0) && (dxPreB<0)) && ((dxCurC>0) && (dxPreC<0)))	return (OP_SELL);
		if ((dxCurA<dxPreA) || (dxCurB<dxPreB) || (dxCurC<dxPreC))
			if (((dxCurB<0) && (dxPreB>0)) && ((dxCurC<0) && (dxPreC>0)))	return (OP_BUY);
	}
 
   return (-1); //нет сигнала
}

int DifMAS(bool bEntry)
{
	//параметры средних 
	int MA5=25;
	int MA7=28;
	int MODE_MA=MODE_EMA;
	int PRICE=PRICE_MEDIAN;
	int PERIOD=PERIOD_H1;

   double dxCurA, dxPreA;
	double dx2, dx1, x, x0, x1, xx1, xx2;
	x = iMA(NULL, PERIOD, MA5, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA5, 0, MODE_MA, PRICE, 1); dx1 = x-x0; xx1 = x0;
	x = iMA(NULL, PERIOD, MA7, 0, MODE_MA, PRICE, 0);	x0 = iMA(NULL, 0, MA7, 0, MODE_MA, PRICE, 1); dx2 = x-x0; xx2 = x0;
	dxCurA = 100*(dx1-dx2);
	x1 = iMA(NULL, PERIOD, MA5, 0, MODE_MA, PRICE, 2); dx1 = xx1-x1;
	x1 = iMA(NULL, PERIOD, MA7, 0, MODE_MA, PRICE, 2); dx2 = xx2-x1;
	dxPreA = 100*(dx1-dx2);

	//----- условия для совершения операции
	if (bEntry)   //для открытия
	{
		if ((dxCurA>0) && (dxPreA<0))	return (OP_BUY);
		if ((dxCurA<0) && (dxPreA>0))	return (OP_SELL);
	}
	else //для закрытия
	{	
		if ((dxCurA>0) && (dxPreA<0))	return (OP_SELL);
		if ((dxCurA<0) && (dxPreA>0))	return (OP_BUY);
	}
 
   return (-1); //нет сигнала
}

int CCI()
{
   int periodCCI = 55;//Период усреднения для вычисления индикатора.
   int applied_price = 0;//Используемая цена. Может быть любой из ценовых констант.
   int shift = 0;//сдвиг относительно текущего бара на указанное количество периодов назад
   int CCI_High = 100;
   int CCI_Low = 100;
   
   double CCICurrent=iCCI(NULL,0,periodCCI,applied_price,shift);
   double CCIPrevious=iCCI(NULL,0,periodCCI,applied_price,shift+1);
    
    int vSignal = 0;
    if(CCICurrent<-CCI_Low && CCIPrevious>-CCI_Low) return (OP_BUY); 
    else
    if(CCICurrent>CCI_High && CCIPrevious<CCI_High) return (OP_SELL);

    
   return (-1); //нет сигнала
} 
