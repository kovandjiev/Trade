//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "4.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>
#include <PSTrendDetector.mqh>

#define MAX_SIGNAL_ID 14

class PSSignals
{
	public:
		PSSignals(CFileLog *fileLog, string symbol, int period, int openSignalId, int digits, double dynOpenCoeff = 0.0, int closeSignalId = 1, double dynCloseCoeff = 0.0);
		~PSSignals();
		bool IsInitialised();
		int Open();
		int Close(int orderType);
		int GetMagicNumber();
		bool IsMagicNumberBelong(int magicNumber);
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

		int _magicNumber;
		int _maxMagicNumber;
		void BuildMagicNumber();
		
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

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period, int openSignalId, int digits, double dynOpenCoeff, int closeSignalId, double dynCloseCoeff)
{
	_trendDetector = new PSTrendDetector(fileLog, symbol, period, digits);
	_market = new PSMarket(fileLog, symbol, period, digits);

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
		BuildMagicNumber();
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
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSSignals is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSSignals is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period, 
			", Signal Id: ", _openSignalId));
	}
}

bool PSSignals::IsInitialised()
{
	return _isInitialised;
}

void PSSignals::BuildMagicNumber()
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

	_magicNumber = 
		symbolId * 100000000 +
		periodId * 10000000 +
		_openSignalId * 100000; //+
		//_signalCloseId * 1000;
	
	_maxMagicNumber = _magicNumber + 99999;
}

int PSSignals::GetMagicNumber()
{
	return _magicNumber;
}

// @brief Check if magic number belong this object.
bool PSSignals::IsMagicNumberBelong(int magicNumber)
{
	return magicNumber >= _magicNumber && magicNumber <= _maxMagicNumber;
}

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
		// MyIdea1, old 20
		case 1: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.Current1OsMA6_45_5(), _trendDetector.Low1MA8_M15()); break;
		// new AO + low, high filter
		case 2: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentAO(), _trendDetector.Low1MA8_M15()); break; 
		// Use Use iIchimoku Tenkan Sen for current + low, high filter
		case 3: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentIchimoku(), _trendDetector.Low1MA8_M15()); break;
		// new MA + ATR filter
		case 4: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentMaAtrFlt(_dynOpenCoeff), _trendDetector.Low1MA8_M15()); break;
		// MyIdea2. Isn't more good than MyIdea1
		case 5: CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentOsMA12_26_9(), _trendDetector.Low1MA8_M15()); break;
		// T1Signal, old 8
		case 6: result = _trendDetector.CurrentT1Signal(true, 10, 100); break;
		// T2Signal, old 9
		case 7: result = _trendDetector.CurrentT2Signal2(); break;
		// Exp12 old 19
		case 8: result = CheckAreSame(_trendDetector.High1MAMANK(), _trendDetector.CurrentJtatl4(), _trendDetector.Low1MA8_M15()); break;
		// Exp11, old 22
		case 9: result = _trendDetector.Exp11(true); break;
		// HLHBTrendCatcher1, old 12
		case 10: result = _trendDetector.CurrentHLHBTrendCatcher(false, false); break;
		// HLHBTrendCatcher2, old 13
		case 11: result = _trendDetector.CurrentHLHBTrendCatcher(true, false); break;
		// HLHBTrendCatcher3
		case 12: result = _trendDetector.CurrentHLHBTrendCatcher(false, true); break;
		// HLHBTrendCatcher4, old 15
		case 13: result = _trendDetector.CurrentHLHBTrendCatcher(true, true); break;
		//case MAX_SIGNAL_ID: 
		// Use iIchimoku Tenkan Sen for current detect and iIchimoku Kijun Sen for high trend. 
		case 14: result = CheckAreSame(_trendDetector.CurrentIchimokuHigh(), _trendDetector.CurrentIchimoku(), _trendDetector.Low1MA8_M15()); break;

		// It isn't profitable strategy.
		//case 3: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentBearsBulls(), _trendDetector.Low1MA8_M15()); break; // new Bulls and Bears + low, high filter
		// It does more Drawdown than MyIdea1
		//case 2: result = MyIdea2(); break;
		// TODO: It must be refactoring. Signals are missmached.
		//case 3: result = DuplicateOpenFilter(_trendDetector.CurrentCspLine());
		// TODO: It must be refactoring. Signals are missmached.
		//case 4: result = DuplicateOpenFilter(_trendDetector.CurrentCollaps());
		// TODO: It must be refactoring. Small signals.
		//case 5: result = DuplicateOpenFilter(_trendDetector.CurrentEnvelop());
		// TODO: It must be refactoring. Signals are missmached.
		//case 6: result = DuplicateOpenFilter(_trendDetector.CurrentWpr());
		// TODO: It must be refactoring.
		//case 8: result = DuplicateOpenFilter(_trendDetector.Current3MA2SAR());
		// TODO: It must be refactoring. Signals are mismatched.
		//case 12: result = _trendDetector.CurrentDifMA();
		// TODO: It must be refactoring. Signals are too small.
		//case 14: result = DuplicateOpenFilter(_trendDetector.CurrentInsideBar());
		// TODO: It must be refactoring. It doesn't send signals.
		//case 15: result = _trendDetector.CurrentBUOVB_BEOVB();
		// It react slower than _trendDetector.CurrentT1Signal1(true);
		//case 17: result = _trendDetector.CurrentT1Signal2(true);
		// TODO: It must be refactoring. Signals are mismatched.
		//case 18: result = _trendDetector.CurrentT2Signal1();
		// TODO: It must be refactoring. Signals are mismatched.
		//case 27: result = _trendDetector.CurrentSMACrossoverPullback();
		// TODO: It must be refactoring. Signals are mismatched.
		//case 31: result = CheckAreSame(_trendDetector.High1StepMAStoch(), _trendDetector.CurrentExp14M(), _trendDetector.Low1MA8_M15());
		// 20190219 Rejected after Stojan & Plamen review.
		// case 1: result = DuplicateOpenFilter(_trendDetector.CurrentShip()); break;
		// case 2: result = DuplicateOpenFilter(_trendDetector.High4MA4_8(), _trendDetector.Current5MA()); // Old 2
		// case 3: result = DuplicateOpenFilter(_trendDetector.CurrentCalc1Wpr()); // old 7, old 3 
		// case 4: result = _trendDetector.CurrentMacd(true);  break;// old 9
		// case 5: result = DuplicateOpenFilter(_trendDetector.CurrentSidus(true)); break; // old 10
		// case 6: result = NearOpenFilter(_trendDetector.CurrentSidusSafe(true), 3); break; // old 11
		// case 7: result = DuplicateOpenFilter(_trendDetector.CurrentZigZag()); break; // old 13
		// case 10: result = NearOpenFilter(_trendDetector.CurrentT4Signal(), 5); break; // old 20
		// case 11: result = NearOpenFilter(_trendDetector.ASCT_RAVI(), 3); break; // old 21
		// case 16: result = NearOpenFilter(_trendDetector.CurrentSTBollingerRev(), 5); // old 26
		// case 17: result = _trendDetector.CurrentExp11M(); break; // old 28
		// case 18: result = CheckAreSame(_trendDetector.High2MA3(), _trendDetector.CurrentExp11M()); break; // old 29
		// case 19: result = CheckAreSame(_trendDetector.High1MAMANK(), _trendDetector.CurrentExp12M(), _trendDetector.Low1JFatl_M5()); // old 30 466
		// case 21: result = NearOpenFilter(_trendDetector.The3Ducks(), 5); break; // old 33

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
