//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "3.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>
#include <PSTrendDetector.mqh>

#define MAX_SIGNAL_ID 72

class PSSignals
{
	public:
		PSSignals(CFileLog *fileLog, string symbol, int period, int openSignalId, int digits, double points, double dynOpenCoeff = 0.2, int closeSignalId = 1, double dynCloseCoeff = 0.0);
		~PSSignals();
		bool IsInitialised();
		int Open();
		int Close(int orderType);
		int GetMagicNumber(int number = 0);

	private:
		CFileLog *_fileLog;
		PSTrendDetector *_trendDetector;
		PSMarket *_market;
		
		string _symbol;
		int _period;

		bool _isInitialised;
		void CheckInputValues();

		int _openSignalId;
		int _closeSignalId;
		double _dynOpenCoeff;
		double _dynCloseCoeff;

		int _lastBarOpenNum;
		int _lastBarCloseNum;
		bool IsNewBar(bool isOpen);

		int _lastCloseDirection;
		int _lastOpenDirection;
		
		int DuplicateCloseFilter(int currentDirection);

		int CheckAreSame(int highDirection, int currentDirection);
		int CheckAreSame(int highDirection, int currentDirection, int lowDirection);
		
		int DuplicateOpenFilter(int currentDirection);
		int DuplicateOpenFilter(int highDirection, int currentDirection);
		int DuplicateOpenFilter(int highDirection, int currentDirection, int lowDirection);
		
		int _nearOpenFilterBar;
		int _nearOpenFilterDirection;
		int NearOpenFilter(int currentDirection, int nearBar = 1);

		int ReverseSignal(int currentDirection);

		int _nearCloseFilterBar;
		int _nearCloseFilterDirection;
		int NearCloseFilter(int currentDirection, int nearBar = 1);

		int _lastSameCloseDirection;
		int LastSameCloseFilter(int currentDirection);

		int DetectClose(int orderType, int currentDirection);
};

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period, int openSignalId, int digits, double points, double dynOpenCoeff, int closeSignalId, double dynCloseCoeff)
{
	_trendDetector = new PSTrendDetector(fileLog, symbol, period, digits, points);
	_market = new PSMarket(fileLog, symbol, period, digits, points);

	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_openSignalId = openSignalId;
	_closeSignalId = closeSignalId;
	_dynOpenCoeff = dynOpenCoeff; 
	_dynCloseCoeff = dynCloseCoeff;

	CheckInputValues();

	if (_isInitialised) 
	{
		//BuildMagicNumber();
	}
		
	_lastBarOpenNum = 0;
	_lastOpenDirection = OP_NONE;
	
	_lastBarCloseNum = 0;
	_lastCloseDirection = OP_NONE;

	_nearOpenFilterBar = 0;
	_nearOpenFilterDirection = OP_NONE;

	_nearCloseFilterBar = 0;
	_nearCloseFilterDirection = OP_NONE;

	_lastSameCloseDirection = OP_NONE;
}

PSSignals::~PSSignals()
{
	delete _trendDetector;
	delete _market;
}

void PSSignals::CheckInputValues()
{
	bool log = _fileLog != NULL;
	if (!log) {
		//_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		Print(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		_isInitialised = false;
		return;
	}
	
	bool trendDetector = _trendDetector.IsInitialised();
	if (!trendDetector) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " TrendDetector is not initialised!"));
	}

	bool symbol = IsSymbolValid(_symbol);
	if (!symbol) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = IsTimeFrameValid(_period);
	if (!period) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

	bool signal = _openSignalId > 0 && _openSignalId <= MAX_SIGNAL_ID;
	if (!signal) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " SignalId: ", _openSignalId, " must be from: 1 to ", MAX_SIGNAL_ID));
	}

	_isInitialised = log && trendDetector && symbol && period && signal;

	if (!_isInitialised) 
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSSignals2 is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSSignals2 is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period, 
			", Signal Id: ", _openSignalId));
	}
}

bool PSSignals::IsInitialised()
{
	return _isInitialised;
}

// @brief Check if magic number belong this object.
// @param number Number sends from EA. Maximum 99999.
// @return int Magic number.
int PSSignals::GetMagicNumber(int number = 0)
{
	// int max is 2 147 483 647
	// 1 111 111 111
	//   | -  symbol
	//    | - period
	//     | | - signal open Id
	//        || - signal close
	//           ||| - ???

	int symbolId = GetSymbolIndex(_symbol);
	int periodId = GetTimeFrameIndex(_period);

	int magicNumber = 
		symbolId * 100000000 +
		periodId * 10000000 +
		_openSignalId * 100000 +
		number;
		
	return magicNumber;
}

// @brief Check if magic number belong this object.
// bool PSSignals::IsMagicNumberBelong(int magicNumber)
// {
// 	return magicNumber >= _magicNumber && magicNumber <= _maxMagicNumber;
// }

bool PSSignals::IsNewBar(bool isOpen)
{
	int currentBarNumber = iBars(_symbol, _period);

	// Process logics only if new bar is appaired.
	if (isOpen) 
	{
		if(currentBarNumber == _lastBarOpenNum)
		{
			return false;
		}

		_lastBarOpenNum = currentBarNumber;
	}
	else
	{
		if(currentBarNumber == _lastBarCloseNum)
		{
			return false;
		}

		_lastBarCloseNum = currentBarNumber;
	}

   return true;
}

// @brief Process open signals
// @return OP_NONE - isn't necessary any action, OP_BUY - open Buy orders, OP_SELL - open sell orders.
int PSSignals::Open()
{
	if (!IsNewBar(true)) {
		return OP_NONE;
	}

	int result = OP_NONE;

	switch (_openSignalId)
	{
		// ++++++ Profitable
		// MyIdea1, old 20
		case 1: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.Current1OsMA6_45_5(), _trendDetector.Low1MA8_M15()); break;
		// new AO + low, high filter
		case 2: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentAO(), _trendDetector.Low1MA8_M15()); break; 
		// Use Use iIchimoku Tenkan Sen for current + low, high filter
		case 3: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentIchimoku(), _trendDetector.Low1MA8_M15()); break;
		case 4: result = _trendDetector.CurrentMomentumMacd(); break;

		// ------- Isn't profitable
		case 5: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentMaAtrFlt(_dynOpenCoeff), _trendDetector.Low1MA8_M15()); break;
		// MyIdea2. Isn't more good than MyIdea1
		case 6: CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentOsMA12_26_9(), _trendDetector.Low1MA8_M15()); break;
		case 7: result = _trendDetector.CurrentT1Signal(true, 10, 100); break;
		case 8: result = _trendDetector.CurrentT2Signal2(); break;
		case 9: result = CheckAreSame(_trendDetector.High1MAMANK(), _trendDetector.CurrentJtatl4(), _trendDetector.Low1MA8_M15()); break;
		case 10: result = _trendDetector.Exp11(true); break;
		case 11: result = _trendDetector.CurrentHLHBTrendCatcher(true, false, false); break;
		case 12: result = _trendDetector.CurrentHLHBTrendCatcher(true, true, false); break;
		case 13: result = _trendDetector.CurrentHLHBTrendCatcher(true, false, true); break;
		case 14: result = _trendDetector.CurrentHLHBTrendCatcher(true, true, true); break;
		case 15: result = _trendDetector.CurrentHLHBTrendCatcher(false, false, false); break;

		case 16: result = _trendDetector.CurrentSAR(); break;
		case 17: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentSAR(), _trendDetector.Low1MA8_M15()); break;
        case 18: result = _trendDetector.Current1OsMA6_45_5(); break;
        case 19: result = _trendDetector.CurrentAO(); break;
        case 20: result = _trendDetector.CurrentIchimoku(); break;
		// Use iIchimoku Tenkan Sen for current detect and iIchimoku Kijun Sen for high trend. 
		case 21: result = CheckAreSame(_trendDetector.HighIchimoku(), _trendDetector.CurrentIchimoku(), _trendDetector.Low1MA8_M15()); break;
        case 22: result = _trendDetector.CurrentMomentum(); break;
		case 23: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentMomentum(), _trendDetector.Low1MA8_M15()); break;
        case 24: result = _trendDetector.CurrentOsMA(); break;
		case 25: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentOsMA(), _trendDetector.Low1MA8_M15()); break;
        case 26: result = _trendDetector.CurrentRVI(); break;
		case 27: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentRVI(), _trendDetector.Low1MA8_M15()); break;
        case 28: result = _trendDetector.CurrentStochastic(); break;
		case 29: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentStochastic(), _trendDetector.Low1MA8_M15()); break;
        case 30: result = _trendDetector.CurrentWPR(); break;
		case 31: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentWPR(), _trendDetector.Low1MA8_M15()); break;
        case 32: result = _trendDetector.CurrentOsMA12_26_9(); break;
        case 33: result = _trendDetector.CurrentJtatl4(); break;
		case 34: result = _trendDetector.CurrentMacd(); break;
		case 35: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentMacd(), _trendDetector.Low1MA8_M15()); break;
		case 36: result = _trendDetector.CurrentRsi(); break;
		case 37: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentRsi(), _trendDetector.Low1MA8_M15()); break;
		case 38: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentBearsBulls(), _trendDetector.Low1MA8_M15()); break; // new Bulls and Bears + low, high filter
		case 39: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentSTBollingerRev(), _trendDetector.Low1MA8_M15()); break;
		case 40: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentSMACrossoverPullback(), _trendDetector.Low1MA8_M15()); break;
		case 41: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentShip(), _trendDetector.Low1MA8_M15()); break;
		case 42: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.Current5MA(), _trendDetector.Low1MA8_M15()); break;
		case 43: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentCspLine(), _trendDetector.Low1MA8_M15()); break;
		case 44: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentCollaps(), _trendDetector.Low1MA8_M15()); break;
		case 45: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentEnvelop(), _trendDetector.Low1MA8_M15()); break;
		case 46: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentCalc1Wpr(), _trendDetector.Low1MA8_M15()); break;
		case 47: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentWpr(), _trendDetector.Low1MA8_M15()); break;
		case 48: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.Current3MA2SAR(), _trendDetector.Low1MA8_M15()); break;
		case 49: result = _trendDetector.CurrentDifMA();
		case 50: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentDifMA(), _trendDetector.Low1MA8_M15()); break;
		case 51: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentZigZag(), _trendDetector.Low1MA8_M15()); break;
		case 52: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentInsideBar(), _trendDetector.Low1MA8_M15()); break;
		case 53: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentBUOVB_BEOVB(), _trendDetector.Low1MA8_M15()); break;
		case 54: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentT2Signal1(), _trendDetector.Low1MA8_M15()); break;
		case 55: result = _trendDetector.CurrentExp11M(); break;
		case 56: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentExp11M(), _trendDetector.Low1MA8_M15()); break;
		case 57: result = _trendDetector.CurrentExp14M(); break;
		case 58: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentExp14M(), _trendDetector.Low1MA8_M15()); break;
		case 59: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentT4Signal(), _trendDetector.Low1MA8_M15()); break;
		case 60: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentMacd(true), _trendDetector.Low1MA8_M15()); break;
		case 61: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentSidus(true), _trendDetector.Low1MA8_M15()); break;
		case 62: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentSidusSafe(true), _trendDetector.Low1MA8_M15()); break;
		case 63: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.The3Ducks(), _trendDetector.Low1MA8_M15()); break;
		case 64: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.ASCT_RAVI(), _trendDetector.Low1MA8_M15()); break;
		case 65: result = _trendDetector.CurrentT4Signal(); break;
		case 66: result = _trendDetector.CurrentMacd(true); break;
		case 67: result = _trendDetector.CurrentSidus(true); break;
		case 68: result = _trendDetector.CurrentSidusSafe(true); break;
		case 69: result = _trendDetector.The3Ducks(); break;
		case 70: result = _trendDetector.ASCT_RAVI(); break;
		case 71: result = _trendDetector.CurrentADX(); break;
		case MAX_SIGNAL_ID: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentADX(), _trendDetector.Low1MA8_M15()); break;

		default: 
			result = OP_NONE;  break;
	}

	if (result != OP_NONE)
	{
		_trendDetector.ResetCloseValues(result);
	}
	
	return result;
}

// @brief Process close signals
// @return OP_NONE - no action necessary, OP_BUY - close Buy orders, OP_SELL - close sell orders.
int PSSignals::Close(int orderType)
{
	if (orderType == OP_NONE || !IsNewBar(false)) {
		return OP_NONE;
	}

	int result = OP_NONE;
	
	switch (_closeSignalId)
	{
		case 1: result = _trendDetector.CurrentCloseMaAtrFlt(orderType, _dynCloseCoeff); break;
		case 2: result = _trendDetector.CurrentCloseMA7EC(orderType); break;

		case 3: 
				result = result = _trendDetector.CurrentCloseJfatl(orderType); break; // old 22

		default: 
			return result = OP_NONE;
	}
	

	// switch (_openSignalId)
	// {
	// 	case 1: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 2: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 3: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 4: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 5: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 6: result = _trendDetector.CurrentCloseJfatl(orderType); break;
	// 	case 7: result = _trendDetector.CurrentCloseMA7EC(orderType); break;

	// 	case MAX_SIGNAL_ID: 
	// 			result = _trendDetector.CurrentCloseMA7EC(orderType); break; // old 22

	// 	default: 
	// 		return result = OP_NONE;
	// }

	return result;
}

int PSSignals::DetectClose(int orderType, int currentDirection)
{
	if (orderType == OP_NONE || currentDirection == OP_NONE || 
		orderType == currentDirection) 
	{
		return OP_NONE;
	}
	
	return orderType;
}

int PSSignals::LastSameCloseFilter(int currentDirection)
{	
	if (_lastSameCloseDirection != currentDirection) 
	{
		int result = _lastSameCloseDirection;
		_lastSameCloseDirection = currentDirection;

		return result;
	}

	return OP_NONE;
}

int PSSignals::ReverseSignal(int currentDirection)
{	
	if (currentDirection == OP_BUY) 
	{
		return OP_SELL;
	}

	if (currentDirection == OP_SELL) 
	{
		return OP_BUY;
	}
	
	return OP_NONE;
}

int PSSignals::DuplicateCloseFilter(int currentDirection)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	if (_lastCloseDirection != currentDirection) 
	{
		int result = _lastCloseDirection;
		_lastCloseDirection = currentDirection;
		
		return result;
	}
	
	return OP_NONE;
}

int PSSignals::NearCloseFilter(int currentDirection, int nearBar = 1)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	int currentBar = iBars(_symbol, _period);

	if (currentDirection == _nearCloseFilterDirection && (_nearCloseFilterBar + nearBar) >= currentBar ) 
	{
		return OP_NONE;
	}

	_nearCloseFilterBar = currentBar;
	_nearCloseFilterDirection = currentDirection;
	
	return _nearCloseFilterDirection;
}

int PSSignals::DuplicateOpenFilter(int currentDirection)
{	
	if (currentDirection == OP_NONE || _lastOpenDirection == currentDirection) 
	{
		return OP_NONE;
	}
	
	if (currentDirection != _lastOpenDirection)
	{
		_lastOpenDirection = currentDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::NearOpenFilter(int currentDirection, int nearBar = 1)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	int currentBar = iBars(_symbol, _period);

	if (currentDirection == _nearOpenFilterDirection && (_nearOpenFilterBar + nearBar) >= currentBar ) 
	{
		return OP_NONE;
	}

	//if (currentDirection != _nearOpenFilterDirection)
	{
		_nearOpenFilterBar = currentBar;
		_nearOpenFilterDirection = currentDirection;
		
		return _nearOpenFilterDirection;
	}

	return OP_NONE;
}

int PSSignals::DuplicateOpenFilter(int highDirection, int currentDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || highDirection != currentDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && highDirection != _lastOpenDirection)
	{
		_lastOpenDirection = highDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::CheckAreSame(int highDirection, int currentDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || highDirection != currentDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection)
	{
		return highDirection;
	}

	return OP_NONE;
}

int PSSignals::DuplicateOpenFilter(int highDirection, int currentDirection, int lowDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || lowDirection == OP_NONE ||
		highDirection != currentDirection || currentDirection != lowDirection || highDirection != lowDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && currentDirection == lowDirection && highDirection != _lastOpenDirection)
	{
		_lastOpenDirection = highDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::CheckAreSame(int highDirection, int currentDirection, int lowDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || lowDirection == OP_NONE ||
		highDirection != currentDirection || currentDirection != lowDirection || highDirection != lowDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && currentDirection == lowDirection)
	{
		return highDirection;
	}

	return OP_NONE;
}