//+------------------------------------------------------------------+
//|                                                 PSCatchPrice.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// This EA send emails with information if the price marked with first and second lines is reached.
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property strict

//--- input parameters
input string Emails = "name1@mail.com, name2@mail.com"; // The email addresses separated with comma. Example: "name1@mail.com, name2@mail.com"
input ENUM_LINE_STYLE FirstLineStyle = STYLE_DASH; // First line style
input color FirstLineColor = clrGold; // First (closer) line color
input ENUM_LINE_STYLE SecondLineStyle = STYLE_SOLID; // Line style
input color SecondLineColor = clrTomato; // Second (away) line color
input int LineWidth = 1; // Line width

#define FIRST_LINE_NAME "FirstHLine"
#define SECOND_LINE_NAME "SecondHLine"

long _currentChartId;
string _symbol;
int _period;
const int _pipsDistance = 10;
string _emails[];
int _emailCount;
const string _emailSeparator = ",";

// TODO: Process errors.
// TODO: Add Logger.

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  _currentChartId = ChartID();
  _symbol = Symbol();
  _period = Period();

  double point =  Point * ((Digits == 5 || Digits == 3) ? 10 : 1);
  double sellPrice = Ask;

  double linePrice1 = sellPrice - _pipsDistance * point;
  double linePrice2 = sellPrice - _pipsDistance * 2 * point;

  if (CreateHorizontalLine(FIRST_LINE_NAME, linePrice1, FirstLineColor, FirstLineStyle, LineWidth) 
      && CreateHorizontalLine(FIRST_LINE_NAME, linePrice2, SecondLineColor, SecondLineStyle, LineWidth)
      &&  SplitEmails()) {

    return(INIT_SUCCEEDED);
  }

  return(INIT_FAILED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  DeleteHorizontalLine(FIRST_LINE_NAME);
  DeleteHorizontalLine(SECOND_LINE_NAME);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   
}

bool CreateHorizontalLine(
    const string          name,      // line name 
    double                price=0,           // line price 
    const color           clr=clrRed,        // line color 
    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
    const int             width=1           // line width 
    )
  { 

   if(!price) 
   {
      price=SymbolInfoDouble(_symbol, SYMBOL_BID); 
   }


   ResetLastError(); 
  
  // create a horizontal line 
  if(!ObjectCreate(_currentChartId, name, OBJ_HLINE, 0 /*subwindow index*/, 0 /*time of the first anchor point*/, price)) 
  { 
    Print(__FUNCTION__, 
          ": failed to create a horizontal line! Error code = ", GetLastError()); 
    return(false); 
  } 

  ObjectSetInteger(_currentChartId, name, OBJPROP_COLOR, clr); 
  ObjectSetInteger(_currentChartId, name, OBJPROP_STYLE, style); 
  ObjectSetInteger(_currentChartId, name, OBJPROP_WIDTH, width); 
  // Display in the foreground (false) or background (true) 
  ObjectSetInteger(_currentChartId, name, OBJPROP_BACK, false); 
  // Enable (true) or disable (false) the mode of moving the line by mouse 
  // When creating a graphical object using ObjectCreate function, the object cannot be 
  // Highlighted and moved by default. Inside this method, selection parameter 
  //    is true by default making it possible to highlight and move the object 
  ObjectSetInteger(_currentChartId, name, OBJPROP_SELECTABLE, true); 
  ObjectSetInteger(_currentChartId, name, OBJPROP_SELECTED, true); 
  // Hide (true) or display (false) graphical object name in the object list 
  ObjectSetInteger(_currentChartId, name, OBJPROP_HIDDEN, true); 
  // Set the priority for receiving the event of a mouse click in the chart
  ObjectSetInteger(_currentChartId, name, OBJPROP_ZORDER, 0); 

   return(true); 
}

bool DeleteHorizontalLine(const string name)
{
   ResetLastError(); 
   if(!ObjectDelete(_currentChartId,name)) 
     { 
      Print(__FUNCTION__, 
            ": failed to delete a horizontal line: ", name, "! Error code = ", GetLastError()); 
      return(false); 
     } 

   return(true); 
}

bool SplitEmails()
{
  ushort u_sep = StringGetCharacter(_emailSeparator, 0);

  _emailCount = StringSplit(Emails, u_sep, _emails); 
  if (_emailCount <= 0) 
  {
    return false;
  }

  return true;
}

bool SendEmail(bool isFirstLine, double price)
{
  string subject = StringConcatenate(_symbol, " ", isFirstLine ? "First" : "->Second", " level is reached");

  string priceStr = DoubleToStr(price, Digits);
  string body = StringConcatenate("Symbol: ", _symbol, "/r/n", "Period: ", _period, "/r/n", "Price: ", priceStr);

  bool result = true;
  for(int i = 0; i < _emailCount; i++) 
  { 
    result = SendMail(subject, body) && result;
  } 

  return result;
}