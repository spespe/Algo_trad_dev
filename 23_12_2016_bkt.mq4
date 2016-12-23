//+------------------------------------------------------------------+
//|                                                          
//|    Tested on GBPUSD, M5, 01.11.2005 - 29.03.2013
//|    Spread: 3.5, Slippage: 0.0, Min distance of stop from price: 5.0
//+------------------------------------------------------------------+
#property copyright "Pietro Speri"
//+------------------------------------------------------------------+
// -- SL/PT Parameters
//+------------------------------------------------------------------+
// this is the minimum and maximum value for PT & SL used,
// any bigger or smaller value will be capped to this range
extern double MinimumSLPT = 30;
extern double MaximumSLPT = 300;
//+------------------------------------------------------------------+
// -- Money Management Parameters
//+------------------------------------------------------------------+
extern string __s6 = "-----  Money Management Parameters  -----------";
extern bool UseMoneyManagement = false;
extern double Lots = 0.1;
extern int LotsDecimals = 2;
extern double RiskInPercent = 2.0;
extern double MaximumLots = 0.5;
extern bool UseFixedMoney = false;
extern double RiskInMoney = 100.0;
//+------------------------------------------------------------------+
// -- Trading Logic Settings
//+------------------------------------------------------------------+
extern string __s7 = "-----  Trading Logic Settings  ----------------";
extern int MaxTradesPerDay = 0; // 0 means unlimited
extern bool LimitSignalsToRange = false;
extern string TimeRangeFrom = "08:00";
extern string TimeRangeTo = "16:00";
extern bool ExitAtEndOfRange = false;
extern bool ExitAtEndOfDay = false;
extern string ExitTimeEOD = "00:00";
extern bool ExitOnFriday = false;
extern string ExitTimeOnFriday = "00:00";
extern bool TradeLong = true;
extern bool TradeShort = true;
//+------------------------------------------------------------------+
// -- Trading Date Parameters
//+------------------------------------------------------------------+
extern string __s8 = "-----  Trading Date Parameters  ---------------";
extern bool TradeSunday = true;
extern bool TradeMonday = true;
extern bool TradeTuesday = true;
extern bool TradeWednesday = true;
extern bool TradeThursday = true;
extern bool TradeFriday = true;
extern bool TradeSaturday = true;
//+------------------------------------------------------------------+
// -- Other Parameters
//+------------------------------------------------------------------+
extern string __s9 = "-----  Other Parameters  ----------------------";
extern int MaxSlippage = 3;
extern string CustomComment = "Strategy 13.99";
extern int MagicNumber = 12345;
extern bool EmailNotificationOnTrade = false;
extern bool DisplayInfoPanel = true;
//+------------------------------------------------------------------+
// -- Other Hidden Parameters
//+------------------------------------------------------------------+
int MinDistanceOfStopFromPrice = 5.0;
double gPointPow = 0;
double gPointCoef = 0;
double gbSpread = 3.5;
double brokerStopDifference = 0;
string eaStopDifference = "";
double eaStopDifferenceNumber = 0;
int lastHistoryPosChecked = 0;
int lastHistoryPosCheckedNT = 0;
string currentTime = "";
string lastTime = "";
bool tradingRangeReverted = false;
string sqLastPeriod;
bool sqIsBarOpen;
int LabelCorner = 1;
int OffsetHorizontal = 5;
int OffsetVertical = 20;
color LabelColor = White;
int lastDeletedOrderTicket = -1;
bool rettmp;
bool ReplacePendingOrders = false;
/**
 * add your own parameters that will be included in every EA
 * into file /code/CustomParametersMT4.mq4
 */
//extern bool TradeOnHour1 = true;
//+------------------------------------------------------------------+
// -- Functions
//+------------------------------------------------------------------+
int start() {
   drawStats();
   
   if(!customStart()) return(0);
   if(manageTrades()) {
      // we are within trading range hours (if set)
   
      //-------------------------------------------
      // ENTRY RULES
      // LONG: (BollingerBand_Up(23, 4, 0) Crosses Above WMA(67))
      if(TradeLong) {
         bool LongEntryCondition = ((iBands(NULL, 0, 23, 4, 0, PRICE_CLOSE, MODE_UPPER, 2) < iMA(NULL, 0, 67, 0, MODE_LWMA, PRICE_CLOSE, 2)) && (iBands(NULL, 0, 23, 4, 0, PRICE_CLOSE, MODE_UPPER, 1) > iMA(NULL, 0, 67, 0, MODE_LWMA, PRICE_CLOSE, 1)));
         if(LongEntryCondition == true) {
            openPosition(1);
         }
      }
   
      // SHORT: (BollingerBand_Down(23, 4, 0) Crosses Below WMA(67))
      if(TradeShort) {
         bool ShortEntryCondition = ((iBands(NULL, 0, 23, 4, 0, PRICE_CLOSE, MODE_LOWER, 2) > iMA(NULL, 0, 67, 0, MODE_LWMA, PRICE_CLOSE, 2)) && (iBands(NULL, 0, 23, 4, 0, PRICE_CLOSE, MODE_LOWER, 1) < iMA(NULL, 0, 67, 0, MODE_LWMA, PRICE_CLOSE, 1)));
         if(ShortEntryCondition == true) {
            openPosition(-1);
         }
      }
   }
   
   if(getMarketPosition() != 0) {
      manageStop();
   }
   return(0);
}
//+------------------------------------------------------------------+
int init() {
   Log("--------------------------------------------------------");
   Log("Starting the EA");
   double realDigits;
   if(Digits < 2) {
      realDigits = 0;
   } else if (Digits < 4) {
      realDigits = 2;
   } else {
      realDigits = 4;
   }
   gPointPow = MathPow(10, realDigits);
   gPointCoef = 1/gPointPow;
                                                     
   double brokerStopDifferenceNumber = MarketInfo(Symbol(),MODE_STOPLEVEL)/MathPow(10, Digits);
   brokerStopDifference = gPointPow*brokerStopDifferenceNumber;
   eaStopDifferenceNumber = MinDistanceOfStopFromPrice/gPointPow;
   eaStopDifference = DoubleToStr(MinDistanceOfStopFromPrice, 2);
   Log("Broker Stop Difference: ",DoubleToStr(brokerStopDifference, 2),", EA Stop Difference: ",eaStopDifference);
   if(DoubleToStr(brokerStopDifference, 2) != eaStopDifference) {
      Log("WARNING! EA Stop Difference is different from real Broker Stop Difference, the backtest results in MT4 could be different from results of Genetic Builder!");
      
      if(eaStopDifferenceNumber < brokerStopDifferenceNumber) {
         eaStopDifferenceNumber = brokerStopDifferenceNumber;
      }      
   }
   string brokerSpread = DoubleToStr((Ask - Bid)*gPointPow, 2);
   string strGbSpread = DoubleToStr(gbSpread, 2);
   Log("Broker spread: ",brokerSpread,", Genetic Builder test spread: ",strGbSpread);
   if(strGbSpread != brokerSpread) {
      Log("WARNING! Real Broker spread is different from spread used in Genetic Builder, the backtest results in MT4 could be different from results of Genetic Builder!");
   }
   if(TimeStringToDateTime(TimeRangeTo) < TimeStringToDateTime(TimeRangeFrom)) {
      tradingRangeReverted = true;
      Log("Trading range s reverted, from: ", TimeRangeFrom," to ", TimeRangeTo);
   } else {
      tradingRangeReverted = false;
   }
   Log("--------------------------------------------------------");
   customInit();
   if(DisplayInfoPanel) {
      ObjectCreate("line1", OBJ_LABEL, 0, 0, 0);
      ObjectSet("line1", OBJPROP_CORNER, LabelCorner);
      ObjectSet("line1", OBJPROP_YDISTANCE, OffsetVertical + 0 );
      ObjectSet("line1", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("line1", "Strategy 13.99", 9, "Tahoma", LabelColor);
      ObjectCreate("linec", OBJ_LABEL, 0, 0, 0);
      ObjectSet("linec", OBJPROP_CORNER, LabelCorner);
      ObjectSet("linec", OBJPROP_YDISTANCE, OffsetVertical + 16 );
      ObjectSet("linec", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("linec", "Generated by StrategyQuant 3.8.1", 8, "Tahoma", LabelColor);
      ObjectCreate("line2", OBJ_LABEL, 0, 0, 0);
      ObjectSet("line2", OBJPROP_CORNER, LabelCorner);
      ObjectSet("line2", OBJPROP_YDISTANCE, OffsetVertical + 28);
      ObjectSet("line2", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("line2", "------------------------------------------", 8, "Tahoma", LabelColor);
      ObjectCreate("lines", OBJ_LABEL, 0, 0, 0);
      ObjectSet("lines", OBJPROP_CORNER, LabelCorner);
      ObjectSet("lines", OBJPROP_YDISTANCE, OffsetVertical + 44);
      ObjectSet("lines", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("lines", "Last Signal:  -", 9, "Tahoma", LabelColor);
      ObjectCreate("lineopl", OBJ_LABEL, 0, 0, 0);
      ObjectSet("lineopl", OBJPROP_CORNER, LabelCorner);
      ObjectSet("lineopl", OBJPROP_YDISTANCE, OffsetVertical + 60);
      ObjectSet("lineopl", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("lineopl", "Open P/L: -", 8, "Tahoma", LabelColor);
      ObjectCreate("linea", OBJ_LABEL, 0, 0, 0);
      ObjectSet("linea", OBJPROP_CORNER, LabelCorner);
      ObjectSet("linea", OBJPROP_YDISTANCE, OffsetVertical + 76);
      ObjectSet("linea", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("linea", "Account Balance: -", 8, "Tahoma", LabelColor);
      ObjectCreate("lineto", OBJ_LABEL, 0, 0, 0);
      ObjectSet("lineto", OBJPROP_CORNER, LabelCorner);
      ObjectSet("lineto", OBJPROP_YDISTANCE, OffsetVertical + 92);
      ObjectSet("lineto", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("lineto", "Total profits/losses so far: -/-", 8, "Tahoma", LabelColor);
      ObjectCreate("linetp", OBJ_LABEL, 0, 0, 0);
      ObjectSet("linetp", OBJPROP_CORNER, LabelCorner);
      ObjectSet("linetp", OBJPROP_YDISTANCE, OffsetVertical + 108);
      ObjectSet("linetp", OBJPROP_XDISTANCE, OffsetHorizontal);
      ObjectSetText("linetp", "Total P/L so far: -", 8, "Tahoma", LabelColor);
   }
   return(0);
}
//+------------------------------------------------------------------+
int deinit() {
   ObjectDelete("line1");
   ObjectDelete("linec");
   ObjectDelete("line2");
   ObjectDelete("lines");
   ObjectDelete("lineopl");
   ObjectDelete("linea");
   ObjectDelete("lineto");
   ObjectDelete("linetp");
   return(0);
}
//+------------------------------------------------------------------+
double getSpecialSL(double value) {
   return(value);
}
double getSpecialPT(double value) {
   return(value);
}
double getNormalSL(double value) {
   return(value);
}
double getNormalPT(double value) {
   return(value);
}
double getBid() {
   return(Bid);
}
double getAsk() {
   return(Ask);
}
//+------------------------------------------------------------------+
void manageTradeSLPT() {
}
//+------------------------------------------------------------------+
double getTradeOpenPrice(int tradeDirection) {
   RefreshRates();
   if(tradeDirection == 1) {
      // long
         return(Ask);
   } else {
      // short
      return(Bid);
   }
}
//+------------------------------------------------------------------+
double getStopLoss(int tradeDirection) {
   if(tradeDirection == 1) {
      // long
   } else {
      // short
   }
   
   return(0);
}
//+------------------------------------------------------------------+
double getProfitTarget(int tradeDirection) {
   if(tradeDirection == 1) {
      // long
   } else {
      // short
   }
   
   return(0);
}
//+------------------------------------------------------------------+
double getProfitTrailingByTick() {
   if (OrderType() == OP_BUY) {
      // long
   } else if (OrderType() == OP_SELL) {
      // short
   }
   return(0);
}
//+------------------------------------------------------------------+
double getStopTrailingByClose() {
   double value = 0;
   if (OrderType() == OP_BUY) {
   } else if (OrderType() == OP_SELL) {
   }
   return(value);
}
//+------------------------------------------------------------------+
double getMoveSLValueByTick() {
   if (OrderType() == OP_BUY) {
      // long
   } else if (OrderType() == OP_SELL) {
      // short
   }
   return(0);
}
//+------------------------------------------------------------------+
void drawStats() {
    // changed recognition of bar open to support also range/renko charts
   static datetime tmp;
   static double open;
   if (tmp!= Time[0]) { // } || open != Open[0]) { - this doesn't work with renko charts
      tmp =  Time[0];
      open = Open[0];
      sqIsBarOpen = true;
   } else {
      sqIsBarOpen = false;
   }
/*
    // old way of checking for new bar open, doesn't work with range/renko bars
   string currentPeriod = sqGetTimeAsStr();
   if(currentPeriod == sqLastPeriod) {
      sqIsBarOpen = false;
   } else {
      sqLastPeriod = currentPeriod;
      sqIsBarOpen = true;
   }
*/   
   sqTextFillOpens();
   if(sqIsBarOpen) {
      sqTextFillTotals();
   }
}
//+------------------------------------------------------------------+
bool manageTrades() {
   if(Bars<30) {
      Print("NOT ENOUGH DATA: Less Bars than 30");
      return(0);
   }
   closeTradesAtEndOfRange();
   if(!sqIsBarOpen) return(false);
   if(getMarketPosition() != 0) {
      manageTradeSLPT();
   }
   if(LimitSignalsToRange && checkInsideTradingRange() == false) {
      return(false);
   }
   if(!isCorrectDayOfWeek(Time[0])) {
      return(false);
   }
   if(MaxTradesPerDay > 0) {
     if(getNumberOfTradesToday() >= MaxTradesPerDay) {
        return(false);
     }
   }
   return(true);
}
//+------------------------------------------------------------------+
void closeTradesAtEndOfRange() {
   if(isSomeOrderActive() != 0) {
      if(ExitAtEndOfDay) {
         if(ExitTimeEOD == "00:00" || ExitTimeEOD == "0:00") {
            closeTradeFromPreviousDay();
         } else if(TimeCurrent() >= TimeStringToDateTime(ExitTimeEOD)) {
            closeActiveOrders();
            closePendingOrders();
         }
      }
      if(ExitOnFriday) {
         int dow = TimeDayOfWeek(Time[0]);
         if(ExitTimeOnFriday == "00:00" || ExitTimeOnFriday == "0:00") {
            if(dow == 6 || dow == 0 || dow == 1) {
               closeTradeFromPreviousDay();
            }
         } else if(dow == 5 && TimeCurrent() >= TimeStringToDateTime(ExitTimeOnFriday)) {
            closeActiveOrders();
            closePendingOrders();
         }
      }
   }
   if(LimitSignalsToRange) {
      if(checkInsideTradingRange() == false) {
         // we are out of allowed trading hours
         if(ExitAtEndOfRange) {
            if(tradingRangeReverted == false && TimeCurrent() > TimeStringToDateTime(TimeRangeTo)) {
               closeActiveOrders();
               closePendingOrders();
            } else if(tradingRangeReverted == true && TimeCurrent() > TimeStringToDateTime(TimeRangeTo) && TimeCurrent() < TimeStringToDateTime(TimeRangeFrom)) {
               closeActiveOrders();
               closePendingOrders();
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
double gbTrueRange(int period, int index) {
   int period1 = period + index-1;
   int period2 = period + index;
   return (MathMax(High[period1], Close[period2]) - MathMin(Low[period1], Close[period2]));
}
//+------------------------------------------------------------------+
double gbBarRange(int period, int index) {
   int period2 = period + index-1;
   return (MathAbs(High[period2] - Low[period2]));
}
//+------------------------------------------------------------------+
void openPosition(int tradeDirection) {
   if(tradeDirection == 0) return;
   if(checkTradeClosedThisBar()) {
      return;
   }
   if(checkTradeClosedThisMinute()) {
      return;
   }
   //---------------------------------------
   // get order price
   double openPrice = NormalizeDouble(getTradeOpenPrice(tradeDirection), Digits);
   //---------------------------------------
   // get order type
   int orderType;
   if(tradeDirection == 1) {
      if(getMarketPosition() == 1) return;
      if(getMarketPosition() == -1) {
         // close opposite position
         closePositionAtMarket();
      }
      orderType = OP_BUY;
   } else {
      if(getMarketPosition() == -1) return;
      if(getMarketPosition() == 1) {
         // close opposite position
         closePositionAtMarket();
      }
      orderType = OP_SELL;
   }
   if(orderType != OP_BUY && orderType != OP_SELL) {
      // it is stop or limit order
      double AskOrBid;
      if(tradeDirection == 1) { AskOrBid = Ask; } else { AskOrBid = Bid; }
      // check if stop/limit price isn't too close
      if(NormalizeDouble(MathAbs(openPrice - AskOrBid), Digits) <= NormalizeDouble(eaStopDifferenceNumber, Digits)) {
         //Log("stop/limit order is too close to actual price");
         return;
      }
      // check price according to order type
      if(orderType == OP_BUYSTOP) {
         if(AskOrBid >= openPrice) return;
      } else if(orderType == OP_SELLSTOP) {
         if(AskOrBid <= openPrice) return;
      } else if(orderType == OP_BUYLIMIT) {
         if(AskOrBid <= openPrice) return;
      } else if(orderType == OP_SELLLIMIT) {
         if(AskOrBid >= openPrice) return;
      }
      // there can be only one active order of the same type
      if(checkPendingOrderAlreadyExists(orderType)) {
         if(!ReplacePendingOrders) {
            return;
         } else {
            if(!closePendingOrder()) {
                Log("Cannot close existing previous pending order with ticket: ", OrderTicket(),", reason: ", GetLastError());
                return;  
            }
         }
      }
   }
   //---------------------------------------
   // add SL/PT
   double stopLoss = 0;
   double profitTarget = 0;
   double SL = NormalizeDouble(getStopLoss(tradeDirection), Digits);
   double PT = NormalizeDouble(getProfitTarget(tradeDirection), Digits);
   if(SL != 0) {
      stopLoss = openPrice - tradeDirection * SL;
   }
   if(PT != 0) {
      profitTarget = openPrice + tradeDirection * PT;
   }
   string comment = CustomComment;
   double orderLots = getLots(SL*gPointPow);
   if(orderLots > MaximumLots) {
      orderLots = MaximumLots;
   }
   // open order with error handling and retries
   int ticket = 0;
   int retries = 3;
   while(true) {
      retries--;
      if(retries < 0) return;
      if(getMarketPosition() != 0) return;
      if(sqIsTradeAllowed() == 1) {
         ticket = openOrderWithErrorHandling(orderType, orderLots, openPrice, stopLoss, profitTarget, comment, MagicNumber);
         if(ticket > 0) {
            if(tradeDirection > 0) {
                ObjectSetText("lines", "Last Signal: Long, ticket: "+ticket, 8, "Tahoma", LabelColor);
            } else {
                ObjectSetText("lines", "Last Signal: Short, ticket: "+ticket, 8, "Tahoma", LabelColor);
            }
            return;
         }
      }
      if(ticket == -130 || ticket == -131) {
         // invalid stops or volume, we cannot open the trade
         return;
      }
      Sleep(1000);
   }
   return;
}
//+------------------------------------------------------------------+
int openOrderWithErrorHandling(int orderType, double orderLots, double openPrice, double stopLoss, double profitTarget, string comment, int magicNumber) {
   //---------------------------------------
   // send order
   int error, ticket;
   Log("Opening order, direction: ", orderType,", price: ", openPrice, ", Ask: ", Ask, ", Bid: ", Bid);
   ticket = OrderSend(Symbol(), orderType, orderLots, openPrice, MaxSlippage, 0, 0, comment, magicNumber, 0, Green);
   if(ticket < 0) {
      // order failed, write error to log
      error = GetLastError();
      Log("Error opening order: ",error, " : ", ErrorDescription(error));
      return(-error);
   }
   rettmp = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
   Log("Order opened: ", OrderTicket(), " at price:", OrderOpenPrice());
   stopLoss = getSpecialSL(stopLoss);
   profitTarget = getSpecialPT(profitTarget);
   if(EmailNotificationOnTrade) {
      SendMail("GB Strategy - Order opened", getNotificationText());
   }
   // set up stop loss and profit target");
   // It has to be done separately to support ECN brokers
   if(stopLoss != 0 || profitTarget != 0) {
      Log("Setting SL/PT, SL: ", stopLoss, ", PT: ", profitTarget);
      if(OrderModify(ticket, OrderOpenPrice(), stopLoss, profitTarget, 0, 0)) {
         Log("Order modified, StopLoss: ", OrderStopLoss(),", Profit Target: ", OrderTakeProfit());
      } else {
         Log("Error modifying order: ",error, " : ", ErrorDescription(error));
      }
   }
   return(ticket);
}
//+------------------------------------------------------------------+
/**
 * manage trade - move SL to break even or trailing stop
 */
void manageStop() {
    if(!sqIsBarOpen) return;
      
   double trailingStopValue, moveSLValue;
   double orderSL, normalOrderSL, orderOpen;
   double close = Close[1];
   double tsLevel, newSL;
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
         if(OrderOpenTime() >= Time[0]) continue; // exit if the order was just opened
         //------------------------------
         // profit trailing on close
         trailingStopValue = getProfitTrailingByTick();
         if(trailingStopValue > 0) {
            if(OrderType() == OP_BUY) {
               tsLevel = close - trailingStopValue;
            } else {
               tsLevel = close + trailingStopValue;
            }
            orderSL = OrderStopLoss();
            normalOrderSL = getNormalSL(orderSL);
            newSL = getSpecialSL(tsLevel);
            if(OrderType() == OP_BUY) {
               if(isSLCorrect(tsLevel) && (orderSL == 0 || normalOrderSL < tsLevel) && !doublesAreEqual(orderSL, newSL)) {
                  rettmp = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
               }
            } else {
               if (isSLCorrect(tsLevel) && (orderSL == 0 || normalOrderSL > tsLevel)  && !doublesAreEqual(orderSL, newSL)) {
                  rettmp = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
               }
            }
         }
   //--------------------------------------------------------
     // manage stop trailing on close
         trailingStopValue = getStopTrailingByClose();
         if(trailingStopValue > 0) {
            orderOpen = OrderOpenPrice();
            orderSL = OrderStopLoss();
            normalOrderSL = getNormalSL(orderSL);
            newSL = getSpecialSL(trailingStopValue);
            if(OrderType() == OP_BUY) {
               if(isSLCorrect(trailingStopValue) && (orderSL == 0 || normalOrderSL < trailingStopValue) && !doublesAreEqual(orderSL, newSL)) {
              rettmp = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
             }
          } else {
            if (isSLCorrect(trailingStopValue) && (orderSL == 0 || normalOrderSL > trailingStopValue) && !doublesAreEqual(orderSL, newSL)) {
              rettmp = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
             }
          }
         }
         //--------------------------------------------------------
         // manage SL 2 BE (by tick)
         moveSLValue = getMoveSLValueByTick();
         if(moveSLValue > 0) {
            orderSL = OrderStopLoss();
            normalOrderSL = getNormalSL(orderSL);
            orderOpen = OrderOpenPrice();
            newSL = getSpecialSL(orderOpen);
            if(OrderType() == OP_BUY) {
               if(isSLCorrect(orderOpen) && (close - orderOpen >= moveSLValue) && (orderSL == 0 || normalOrderSL < orderOpen) && !doublesAreEqual(orderSL, newSL)) {
                  rettmp = OrderModify(OrderTicket(), orderOpen, newSL, OrderTakeProfit(), 0);
               }
            } else {
               if (isSLCorrect(orderOpen) && (orderOpen - close >= moveSLValue) && (orderSL == 0 || normalOrderSL > orderOpen) && !doublesAreEqual(orderSL, newSL)) {
                  rettmp = OrderModify(OrderTicket(), orderOpen, newSL, OrderTakeProfit(), 0);
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
bool isSLCorrect(double slPrice) {
   if(OrderType() == OP_BUY) {
      if(slPrice < (Bid-eaStopDifferenceNumber)) {
         return(true);
      }
   } else {
      if(slPrice > (Ask+eaStopDifferenceNumber)) {
         return(true);
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool checkPendingOrderAlreadyExists(int orderType) {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == orderType) {
         return(true);
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool closePendingOrder() {
   int ticket = OrderTicket();
   if(OrderDelete(ticket)) {
      lastDeletedOrderTicket = ticket;
      return(true);
   }
   
   return(false);
}
//+------------------------------------------------------------------+
int getMarketPosition() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if(OrderType() == OP_BUY) {
            return(1);
         }
         if(OrderType() == OP_SELL) {
            return(-1);
       }
     }
   }
   return(0);
}
//+------------------------------------------------------------------+
bool isMarketLongPosition() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if(OrderType() == OP_BUY) {
            return(true);
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool isMarketShortPosition() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if(OrderType() == OP_SELL) {
            return(true);
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool isSomeOrderActive() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         return(true);
     }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool checkItIsPendingOrder() {
   if(OrderType() != OP_BUY && OrderType() != OP_SELL) {
     return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool selectOrderByMagicNumber() {
   for(int i=0; i<OrdersTotal(); i++) {
     if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
       return(true);
     }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool selectOpenOrderByMagicNumber() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if(checkItIsPendingOrder()) {
            continue;
         }
         return(true);
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
void closePositionAtMarket() {
   RefreshRates();
   double priceCP;
   if(OrderType() == OP_BUY) {
      priceCP = Bid;
   } else {
      priceCP = Ask;
   }
   rettmp = OrderClose(OrderTicket(), OrderLots(), priceCP, MaxSlippage);
}
//+------------------------------------------------------------------+
void Log(string s1, string s2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="" ) {
   Print(TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS), " ", s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
}
//+------------------------------------------------------------------+
void closeTradeFromPreviousDay() {
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         int orderType = OrderType();
         if(TimeToStr(Time[0], TIME_DATE) != TimeToStr(OrderOpenTime(), TIME_DATE)) {
            if (orderType == OP_BUY || orderType == OP_SELL) {
               closePositionAtMarket();
            } else {
               closePendingOrder();
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
double getHighest(int period, int shift) {
   double maxnum = -1000000;
   for(int i=shift; i<shift+period; i++) {
      if(High[i] > maxnum) {
         maxnum = High[i];
      }
   }
   return(maxnum);
}
//+------------------------------------------------------------------+
double getLowest(int period, int shift) {
   double minnum = 1000000;
   for(int i=shift; i<shift+period; i++) {
      if(Low[i] < minnum) {
         minnum = Low[i];
      }
   }
   return(minnum);
}
//+------------------------------------------------------------------+
bool timeIsLower(datetime dt, int toHour, int toMinute) {
 if(toHour == 0 && TimeHour(dt) == 23) return (true);
 if(TimeHour(dt) < toHour) return(true);
 if(TimeHour(dt) > toHour) return (false);
 if(TimeMinute(dt) < toMinute) return (true);
 if(TimeMinute(dt) >  toMinute) return (false);
 return (false);
}
bool timeIsBiggerOrEqual(datetime dt, int toHour, int toMinute) {
  if(TimeHour(dt) < toHour) return (false);
  if(TimeHour(dt) > toHour) return (true);
  if(TimeMinute(dt) < toMinute) return (false);
  if(TimeMinute(dt) >=  toMinute) return (true);
  return (false);
}
//+------------------------------------------------------------------+
double getHighestInRange(int fromHour, int fromMinute, int toHour, int toMinute) {
   int indexTo = -1;
   int indexFrom = -1;
   int i;
   // find index of bar for timeTo
   for(i=1; i<=100; i++) {
      if(timeIsBiggerOrEqual(Time[i], toHour, toMinute) && timeIsLower(Time[i+1], toHour, toMinute)) {
         indexTo = i;
         break;
      }
   }
   if(indexTo == -1) {
      Log("Not found indexTo");
      return(-1);
   }
   // find index of bar for timeFrom
   for(i=1; i<=100; i++) {
      if(i <= indexTo) continue;
      if(timeIsBiggerOrEqual(Time[i], fromHour, fromMinute) && timeIsLower(Time[i+1], fromHour, fromMinute)) {
         indexFrom = i;
         break;
      }
   }
   if(indexFrom == -1) {
      Log("Not found indexFrom");
      return(0);
   }
   double value = -10000.0;
   for(i=indexTo; i<=indexFrom; i++) {
      value = MathMax(value, iHigh(NULL, 0, i));
   }
   return(value);
}
//+------------------------------------------------------------------+
double getLowestInRange(int fromHour, int fromMinute, int toHour, int toMinute) {
   int indexTo = -1;
   int indexFrom = -1;
   int i;
   // find index of bar for timeTo
   for(i=1; i<=100; i++) {
      if(timeIsBiggerOrEqual(Time[i], toHour, toMinute) && timeIsLower(Time[i+1], toHour, toMinute)) {
         indexTo = i;
         break;
      }
   }
   if(indexTo == -1) {
      Log("Not found indexTo");
      return(-1);
   }
   // find index of bar for timeFrom
   for(i=1; i<=100; i++) {
      if(i <= indexTo) continue;
      if(timeIsBiggerOrEqual(Time[i], fromHour, fromMinute) && timeIsLower(Time[i+1], fromHour, fromMinute)) {
         indexFrom = i;
         break;
      }
   }
   if(indexFrom == -1) {
      Log("Not found indexFrom");
      return(0);
   }
   double value = 100000.0;
   for(i=indexTo; i<=indexFrom; i++) {
      value = MathMin(value, iLow(NULL, 0, i));
   }
   return(value);
}
//+------------------------------------------------------------------+
double getTimeRange(int fromHour, int fromMinute, int toHour, int toMinute) {
   return(getHighestInRange(fromHour, fromMinute, toHour, toMinute) - getLowestInRange(fromHour, fromMinute, toHour, toMinute));
}
//+------------------------------------------------------------------+
void manageOrdersExpiration() {
   currentTime = getPeriodAsStr();
   if(currentTime == lastTime) {
      return;
   }
   int barsOpen = 0;
   int orderType;
   int exitBars = 0;
   int expiration = 0;
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         orderType = OrderType();
         if (orderType == OP_BUY || orderType == OP_SELL) {
            // it is active order
            // do nothing
         } else {
            // it is stop/limit pending order
            if(orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
            } else if (orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) {
            }
         }
      }
   }
   lastTime = currentTime;
}
//+------------------------------------------------------------------+
void closePendingOrders() {
   int orderType;
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         orderType = OrderType();
         if (orderType == OP_BUY || orderType == OP_SELL) {
            continue;
         }
         closePendingOrder();
      }
   }
}
//+------------------------------------------------------------------+
void closeActiveOrders() {
   int orderType;
   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         orderType = OrderType();
         if (orderType == OP_BUY || orderType == OP_SELL) {
            closePositionAtMarket();
         }
      }
   }
}
//+------------------------------------------------------------------+
int getOpenBarsForOrder(int expBarsPeriod) {
   datetime opTime = OrderOpenTime();
   int numberOfBars = 0;
   for(int i=0; i<expBarsPeriod+10; i++) {
      if(opTime < Time[i]) {
         numberOfBars++;
      }
   }
   return(numberOfBars);
}
//+------------------------------------------------------------------+
string getPeriodAsStr() {
   string str = TimeToStr(TimeCurrent(), TIME_DATE);
   int period = Period();
   if(period == PERIOD_H4 || period == PERIOD_H1) {
      str = str + TimeHour(TimeCurrent());
   }
   if(period == PERIOD_M30 || period == PERIOD_M15 || period == PERIOD_M5 || period == PERIOD_M1) {
      str = str + " " + TimeToStr(TimeCurrent(), TIME_MINUTES);
   }
   return(str);
}
//+------------------------------------------------------------------+
bool checkTradeClosedThisMinute() {
   string currentTime2 = TimeToStr( TimeCurrent(), TIME_DATE|TIME_MINUTES);
   int startAt = lastHistoryPosChecked-10;
   if(startAt < 0) {
      startAt = 0;
   }
   for(int i=startAt;i<OrdersHistoryTotal();i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         string orderTime = TimeToStr( OrderCloseTime(), TIME_DATE|TIME_MINUTES);
         if(lastDeletedOrderTicket != -1 && OrderTicket() == lastDeletedOrderTicket) {
            // skip deleted orders, only count real triggered orders
            continue;
         }
         
         lastHistoryPosChecked = i;
         if(orderTime == currentTime2) {
            return(true);
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool checkTradeClosedThisBar() {
   int startAt = lastHistoryPosChecked-10;
   if(startAt < 0) {
      startAt = 0;
   }
   for(int i=startAt;i<OrdersHistoryTotal();i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         if((OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderCloseTime() >= Time[0]) {
            return(true);
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
int getNumberOfTradesToday() {
   int i;
   string orderTime;
   int startAt = lastHistoryPosCheckedNT-10;
   if(startAt < 0) {
      startAt = 0;
   }
   string currentTime2 = TimeToStr( TimeCurrent(), TIME_DATE);
   int count = 0;
   for(i=startAt;i<OrdersHistoryTotal();i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         orderTime = TimeToStr( OrderOpenTime(), TIME_DATE);
         lastHistoryPosCheckedNT = i;
         if(orderTime == currentTime2) {
            count++;
         }
      }
   }
   for(i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
         orderTime = TimeToStr( OrderOpenTime(), TIME_DATE);
         if(orderTime == currentTime2) {
            count++;
         }
      }
   }
   return(count);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
double getLots(double slSize) {
   if(slSize <= 0) {
      return(Lots);
   }
   if(UseMoneyManagement == false) {
      if(Lots > MaximumLots) {
         return(MaximumLots);
      }
      return(Lots);
   }
   if(UseFixedMoney) {
      return(getLotsFixedMoney(slSize));
   } else {
      return(getLotsRiskPercentage(slSize));
   }
}
//+------------------------------------------------------------------+
double getLotsFixedMoney(double slSize) {
   if(RiskInMoney <0 ) {
      Log("Incorrect RiskInPercent size, it must be above 0");
      return(0);
   }
   double riskPerTrade = RiskInMoney;
   return(computeMMFromRiskPerTrade(riskPerTrade, slSize));
}
//+------------------------------------------------------------------+
double getLotsRiskPercentage(double slSize) {
   if(RiskInPercent <0 ) {
      Log("Incorrect RiskInPercent size, it must be above 0");
      return(0);
   }
   double riskPerTrade = (AccountBalance() *  (RiskInPercent / 100.0));
   return(computeMMFromRiskPerTrade(riskPerTrade, slSize));
}
//+------------------------------------------------------------------+
double computeMMFromRiskPerTrade(double riskPerTrade, double slSize) {
   if(slSize <= 0) {
      Log("Incorrect StopLossPips size, it must be above 0");
      return(0);
   }
   // adjust money management for non-US currencies
   double CurrencyAdjuster=1;
   if (MarketInfo(Symbol(),MODE_TICKSIZE)!=0) CurrencyAdjuster=MarketInfo(Symbol(),MODE_TICKVALUE) * (MarketInfo(Symbol(),MODE_POINT) / MarketInfo(Symbol(),MODE_TICKSIZE));
   double lotMM1 = NormalizeDouble(riskPerTrade / CurrencyAdjuster / (slSize * 10.0), LotsDecimals);
   double lotMM;
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(MathMod(lotMM*100, lotStep*100) > 0) {
      lotMM = lotMM1 - MathMod(lotMM1, lotStep);
   } else {
      lotMM = lotMM1;
   }
   lotMM = NormalizeDouble( lotMM, LotsDecimals);
   if(MarketInfo(Symbol(), MODE_LOTSIZE)==10000.0) lotMM=lotMM*10.0 ;
   lotMM=NormalizeDouble(lotMM,LotsDecimals);
   //Log("Computing lots, risk: ", riskPerTrade, ", lotMM1: ", lotMM1, ", lotStep: ", lotStep, ", lots: ", lotMM);
   double Smallest_Lot = MarketInfo(Symbol(), MODE_MINLOT);
   double Largest_Lot = MarketInfo(Symbol(), MODE_MAXLOT);
   if (lotMM < Smallest_Lot) lotMM = Smallest_Lot;
   if (lotMM > Largest_Lot) lotMM = Largest_Lot;
   if(lotMM > MaximumLots) {
      lotMM = MaximumLots;
   }
   //Log("SL size: ", slSize, ", LotMM: ", lotMM);
   return (lotMM);
}
//+------------------------------------------------------------------+
//+ Heiken Ashi functions
//+------------------------------------------------------------------+
double HeikenAshiOpen(int shift) {
   return(iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 2, shift));
}
double HeikenAshiClose(int shift) {
   return(iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 3, shift));
}
double HeikenAshiHigh(int shift) {
   return(MathMax(iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 0, shift), iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 1, shift)));
}
double HeikenAshiLow(int shift) {
   return(MathMin(iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 0, shift), iCustom( NULL, 0, "Heiken Ashi", 0,0,0,0, 1, shift)));
}
//+------------------------------------------------------------------+
//+ Simple rules functions
//+------------------------------------------------------------------+
bool ruleCloseAboveBB() {
   return (Close[1] > iBands(NULL,0, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 1)) ;
}
bool ruleCloseBelowBB() {
   return (Close[1] < iBands(NULL,0, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 1)) ;
}
bool ruleCloseAbovePSAR() {
   return (Close[1] > iSAR(NULL,0, 0.02, 0.2, 1)) ;
}
bool ruleCloseBelowPSAR() {
   return (Close[1] < iSAR(NULL,0, 0.02, 0.2, 1)) ;
}
bool ruleMACD_Above() {
   return (iMACD(NULL,0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1) > 0) ;
}
bool ruleMACD_Below() {
   return (iMACD(NULL,0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1) < 0) ;
}
bool ruleLongTermRSI_Above() {
   return (iRSI(NULL,0,40,PRICE_CLOSE,1) > 50) ;
}
bool ruleLongTermRSI_Below() {
   return (iRSI(NULL,0,40,PRICE_CLOSE,1) < 50) ;
}
bool ruleShortTermRSI_Above() {
   return (iRSI(NULL,0,20,PRICE_CLOSE,1) > 50) ;
}
bool ruleShortTermRSI_Below() {
   return (iRSI(NULL,0,20,PRICE_CLOSE,1) < 50) ;
}
bool ruleLongTermStoch_Above() {
   return (iStochastic(NULL,0, 40, 1, 3, MODE_SMA, 0, 1, 1) > 50) ;
}
bool ruleLongTermStoch_Below() {
   return (iStochastic(NULL,0, 40, 1, 3, MODE_SMA, 0, 1, 1) < 50) ;
}
bool ruleShortTermStoch_Above() {
   return (iStochastic(NULL,0, 20, 1, 3, MODE_SMA, 0, 1, 1) > 50) ;
}
bool ruleShortTermStoch_Below() {
   return (iStochastic(NULL,0, 20, 1, 3, MODE_SMA, 0, 1, 1) < 50) ;
}
bool ruleLongTermCCI_Above() {
   return (iCCI(NULL,0,40,PRICE_TYPICAL,1) > 0) ;
}
bool ruleLongTermCCI_Below() {
   return (iCCI(NULL,0,40,PRICE_TYPICAL,1) < 0) ;
}
bool ruleShortTermCCI_Above() {
   return (iCCI(NULL,0,20,PRICE_TYPICAL,1) > 0) ;
}
bool ruleShortTermCCI_Below() {
   return (iCCI(NULL,0,20,PRICE_TYPICAL,1) < 0) ;
}
bool ruleVolumeAboveAvg() {
   return (Volume[1] > iCustom(NULL,0, "AvgVolume", 50, 1, 1)) ;
}
bool ruleVolumeBelowAvg() {
   return (Volume[1] < iCustom(NULL,0, "AvgVolume", 50, 1, 1)) ;
}
//+------------------------------------------------------------------+
//+ Candle Pattern functions
//+------------------------------------------------------------------+
bool candlePatternBearishEngulfing(int shift) {
   double O = Open[shift];
   double O1 = Open[shift+1];
   double C = Close[shift];
   double C1 = Close[shift+1];
   if ((C1>O1)&&(O>C)&&(O>=C1)&&(O1>=C)&&((O-C)>(C1-O1))) {
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternBullishEngulfing(int shift) {
   double O = Open[shift];
   double O1 = Open[shift+1];
   double C = Close[shift];
   double C1 = Close[shift+1];
   if ((O1>C1)&&(C>O)&&(C>=O1)&&(C1>=O)&&((C-O)>(O1-C1))) {
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternDarkCloudCover(int shift) {
   double L = Low[shift];
   double H = High[shift];
   double O = Open[shift];
   double O1 = Open[shift+1];
   double C = Close[shift];
   double C1 = Close[shift+1];
   double CL = H-L;
   double OC_HL;
   if((H - L) != 0) {
      OC_HL = (O-C)/(H-L);
   } else {
      OC_HL = 0;
   }
   double Piercing_Line_Ratio = 0.5;
   double Piercing_Candle_Length = 10;
   if ((C1>O1)&&(((C1+O1)/2)>C)&&(O>C)&&(C>O1)&&(OC_HL>Piercing_Line_Ratio)&&((CL>=Piercing_Candle_Length*gPointCoef))) {
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternDoji(int shift) {
   if(MathAbs(Open[shift] - Close[shift])*gPointPow < 0.6) {
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternHammer(int shift) {
   double H = High[shift];
   double L = Low[shift];
   double L1 = Low[shift+1];
   double L2 = Low[shift+2];
   double L3 = Low[shift+3];
   double O = Open[shift];
   double C = Close[shift];
   double CL = H-L;
   double BodyLow, BodyHigh;
   double Candle_WickBody_Percent = 0.9;
   double CandleLength = 12;
   if (O > C) {
      BodyHigh = O;
      BodyLow = C;
   } else {
      BodyHigh = C;
      BodyLow = O;
   }
   double LW = BodyLow-L;
   double UW = H-BodyHigh;
   double BLa = MathAbs(O-C);
   double BL90 = BLa*Candle_WickBody_Percent;
   double pipValue = gPointCoef;
   if ((L<=L1)&&(L<L2)&&(L<L3))  {
      if (((LW/2)>UW)&&(LW>BL90)&&(CL>=(CandleLength*pipValue))&&(O!=C)&&((LW/3)<=UW)&&((LW/4)<=UW)/*&&(H<H1)&&(H<H2)*/)  {
         return(true);
      }
      if (((LW/3)>UW)&&(LW>BL90)&&(CL>=(CandleLength*pipValue))&&(O!=C)&&((LW/4)<=UW)/*&&(H<H1)&&(H<H2)*/)  {
         return(true);
      }
      if (((LW/4)>UW)&&(LW>BL90)&&(CL>=(CandleLength*pipValue))&&(O!=C)/*&&(H<H1)&&(H<H2)*/)  {
         return(true);
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternPiercingLine(int shift) {
   double L = Low[shift];
   double H = High[shift];
   double O = Open[shift];
   double O1 = Open[shift+1];
   double C = Close[shift];
   double C1 = Close[shift+1];
   double CL = H-L;
   double CO_HL;
   if((H - L) != 0) {
      CO_HL = (C-O)/(H-L);
   } else {
      CO_HL = 0;
   }
   double Piercing_Line_Ratio = 0.5;
   double Piercing_Candle_Length = 10;
   if ((C1<O1)&&(((O1+C1)/2)<C)&&(O<C) && (CO_HL>Piercing_Line_Ratio)&&(CL>=(Piercing_Candle_Length*gPointCoef))) {
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
bool candlePatternShootingStar(int shift) {
   double L = Low[shift];
   double H = High[shift];
   double H1 = High[shift+1];
   double H2 = High[shift+2];
   double H3 = High[shift+3];
   double O = Open[shift];
   double C = Close[shift];
   double CL = H-L;
   double BodyLow, BodyHigh;
   double Candle_WickBody_Percent = 0.9;
   double CandleLength = 12;
   if (O > C) {
      BodyHigh = O;
      BodyLow = C;
   } else {
      BodyHigh = C;
      BodyLow = O;
   }
   double LW = BodyLow-L;
   double UW = H-BodyHigh;
   double BLa = MathAbs(O-C);
   double BL90 = BLa*Candle_WickBody_Percent;
   double pipValue = gPointCoef;
   if ((H>=H1)&&(H>H2)&&(H>H3))  {
      if (((UW/2)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*pipValue))&&(O!=C)&&((UW/3)<=LW)&&((UW/4)<=LW)/*&&(L>L1)&&(L>L2)*/)  {
         return(true);
      }
      if (((UW/3)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*pipValue))&&(O!=C)&&((UW/4)<=LW)/*&&(L>L1)&&(L>L2)*/)  {
         return(true);
      }
      if (((UW/4)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*pipValue))&&(O!=C)/*&&(L>L1)&&(L>L2)*/)  {
         return(true);
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
bool checkInsideTradingRange() {
   if(tradingRangeReverted == false && (TimeCurrent() < TimeStringToDateTime(TimeRangeFrom) || TimeCurrent() > TimeStringToDateTime(TimeRangeTo))) {
      return(false);
   } else if(tradingRangeReverted == true && (TimeCurrent() > TimeStringToDateTime(TimeRangeTo) && TimeCurrent() < TimeStringToDateTime(TimeRangeFrom))) {
      return(false);
   }
   return(true);
}
//+------------------------------------------------------------------+
bool isCorrectDayOfWeek(datetime time) {
   int dow = TimeDayOfWeek(time);
   if(!TradeSunday && dow == 0) { return(false); }
   if(!TradeMonday && dow == 1) { return(false); }
   if(!TradeTuesday && dow == 2) { return(false); }
   if(!TradeWednesday && dow == 3) { return(false); }
   if(!TradeThursday && dow == 4) { return(false); }
   if(!TradeFriday && dow == 5) { return(false); }
   if(!TradeSaturday && dow == 6) { return(false); }
   return(true);
}
//+------------------------------------------------------------------+
bool doublesAreEqual(double n1, double n2) {
   string s1 = DoubleToStr(n1, Digits);
   string s2 = DoubleToStr(n2, Digits);
   return (s1 == s2);
}
//+------------------------------------------------------------------+
double checkCorrectMinMaxSLPT(double slptValue) {
   double slptMin = MinimumSLPT * gPointCoef;
   if(MinimumSLPT > 0) {
      slptValue = MathMax(MinimumSLPT * gPointCoef, slptValue);
   }
   if(MaximumSLPT > 0) {
      slptValue = MathMin(MaximumSLPT * gPointCoef, slptValue);
   }
   return (slptValue);
}
//+------------------------------------------------------------------+
string getNotificationText() {
   string text = TimeToStr(TimeCurrent());
   text = StringConcatenate(text, " New Order Opened\n\n");
   text = StringConcatenate(text, " Order ticket: ", OrderTicket(),"\n");
   switch(OrderType()) {
      case OP_BUY: text = StringConcatenate(text, " Direction : Buy\n"); break;
      case OP_SELL: text = StringConcatenate(text, " Direction : Sell\n"); break;
      case OP_BUYLIMIT: text = StringConcatenate(text, " Direction : Buy Limit\n"); break;
      case OP_SELLLIMIT: text = StringConcatenate(text, " Direction : Sell Limit\n"); break;
      case OP_BUYSTOP: text = StringConcatenate(text, " Direction : Buy Stop\n"); break;
      case OP_SELLSTOP: text = StringConcatenate(text, " Direction : Sell Stop\n"); break;
   }
   text = StringConcatenate(text, " Open price: ", OrderOpenPrice(),"\n");
   text = StringConcatenate(text, " Lots: ", OrderLots(),"\n");
   return(text);
}
//+------------------------------------------------------------------+
string sqGetTimeAsStr() {
   string str = TimeToStr(Time[0], TIME_DATE);
   int period = Period();
   if(period == PERIOD_H4 || period == PERIOD_H1) {
      str = str + TimeHour(Time[0]);
   }
   if(period == PERIOD_M30 || period == PERIOD_M15 || period == PERIOD_M5 || period == PERIOD_M1) {
      str = str + " " + TimeToStr(Time[0], TIME_MINUTES);
   }
   return(str);
}
//+------------------------------------------------------------------+
int sqIsTradeAllowed(int MaxWaiting_sec = 30) {
    // check whether the trade context is free
    if(!IsTradeAllowed()) {
        int StartWaitingTime = GetTickCount();
        Print("Trade context is busy! Wait until it is free...");
        // infinite loop
        while(true) {
            // if the expert was terminated by the user, stop operation
            if(IsStopped()) {
                Print("The expert was terminated by the user!");
                return(-1);
            }
            // if the waiting time exceeds the time specified in the
            // MaxWaiting_sec variable, stop operation, as well
            int diff = GetTickCount() - StartWaitingTime;
            if(diff > MaxWaiting_sec * 1000) {
                Print("The waiting limit exceeded (" + MaxWaiting_sec + " ???.)!");
                return(-2);
            }
            // if the trade context has become free,
            if(IsTradeAllowed()) {
                Print("Trade context has become free!");
                RefreshRates();
                return(1);
            }
            // if no loop breaking condition has been met, "wait" for 0.1
            // second and then restart checking
            Sleep(100);
          }
    } else {
        //Print("Trade context is free!");
        return(1);
    }
    return(1);
}
//+------------------------------------------------------------------+
double sqToPips(double value) {
    return(value * gPointCoef);
}
//+------------------------------------------------------------------+
void sqTextFillOpens() {
   ObjectSetText("lineopl", "Open P/L: "+DoubleToStr(sqGetOpenPLInMoney(), 2), 8, "Tahoma", LabelColor);
   ObjectSetText("linea", "Account Balance: "+DoubleToStr(AccountBalance(), 2) , 8, "Tahoma", LabelColor);
}
//+------------------------------------------------------------------+
void sqTextFillTotals() {
   ObjectSetText("lineto", "Total profits/losses so far: "+sqGetTotalProfits(500)+"/"+sqGetTotalLosses(500), 8, "Tahoma", LabelColor);
   ObjectSetText("linetp", "Total P/L so far: "+DoubleToStr(sqGetTotalClosedPLInMoney(5000), 2), 8, "Tahoma", LabelColor);
}
//+------------------------------------------------------------------+
double sqGetOpenPLInMoney() {
   double pl = 0;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      pl += OrderProfit();
   }
   return(pl);
}
//+------------------------------------------------------------------+
int sqGetTotalProfits(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int profits = 0;
   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MagicNumber) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;
            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }
            if(pl > 0) {
               profits++;
            }
            if(count >= numberOfLastOrders) break;
         }
      }
   }
   return(profits);
}
//+------------------------------------------------------------------+
int sqGetTotalLosses(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int losses = 0;
   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MagicNumber) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;
            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }
            if(pl < 0) {
               losses++;
            }
            if(count >= numberOfLastOrders) break;
         }
      }
   }
   return(losses);
}
//+------------------------------------------------------------------+
double sqGetTotalClosedPLInMoney(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MagicNumber) {
            // return the P/L of last order or the P/L of last order with given Magic Number
            count++;
            pl = pl + OrderProfit();
            if(count >= numberOfLastOrders) break;
         }
      }
   }
   return(pl);
}
//+------------------------------------------------------------------+
datetime TimeStringToDateTime(string time) {
   string date = TimeToStr(TimeCurrent(),TIME_DATE);//"yyyy.mm.dd"
   return (StrToTime(date + " " + time));
}
//+------------------------------------------------------------------+
//| return error description                                         |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code)
  {
   string error_string;
//----
   switch(error_code)
     {
      //---- codes returned from trade server
      case 0:
      case 1:   error_string="no error";                                                  break;
      case 2:   error_string="common error";                                              break;
      case 3:   error_string="invalid trade parameters";                                  break;
      case 4:   error_string="trade server is busy";                                      break;
      case 5:   error_string="old version of the client terminal";                        break;
      case 6:   error_string="no connection with trade server";                           break;
      case 7:   error_string="not enough rights";                                         break;
      case 8:   error_string="too frequent requests";                                     break;
      case 9:   error_string="malfunctional trade operation (never returned error)";      break;
      case 64:  error_string="account disabled";                                          break;
      case 65:  error_string="invalid account";                                           break;
      case 128: error_string="trade timeout";                                             break;
      case 129: error_string="invalid price";                                             break;
      case 130: error_string="invalid stops";                                             break;
      case 131: error_string="invalid trade volume";                                      break;
      case 132: error_string="market is closed";                                          break;
      case 133: error_string="trade is disabled";                                         break;
      case 134: error_string="not enough money";                                          break;
      case 135: error_string="price changed";                                             break;
      case 136: error_string="off quotes";                                                break;
      case 137: error_string="broker is busy (never returned error)";                     break;
      case 138: error_string="requote";                                                   break;
      case 139: error_string="order is locked";                                           break;
      case 140: error_string="long positions only allowed";                               break;
      case 141: error_string="too many requests";                                         break;
      case 145: error_string="modification denied because order too close to market";     break;
      case 146: error_string="trade context is busy";                                     break;
      case 147: error_string="expirations are denied by broker";                          break;
      case 148: error_string="amount of open and pending orders has reached the limit";   break;
      case 149: error_string="hedging is prohibited";                                     break;
      case 150: error_string="prohibited by FIFO rules";                                  break;
      //---- mql4 errors
      case 4000: error_string="no error (never generated code)";                          break;
      case 4001: error_string="wrong function pointer";                                   break;
      case 4002: error_string="array index is out of range";                              break;
      case 4003: error_string="no memory for function call stack";                        break;
      case 4004: error_string="recursive stack overflow";                                 break;
      case 4005: error_string="not enough stack for parameter";                           break;
      case 4006: error_string="no memory for parameter string";                           break;
      case 4007: error_string="no memory for temp string";                                break;
      case 4008: error_string="not initialized string";                                   break;
      case 4009: error_string="not initialized string in array";                          break;
      case 4010: error_string="no memory for array\' string";                             break;
      case 4011: error_string="too long string";                                          break;
      case 4012: error_string="remainder from zero divide";                               break;
      case 4013: error_string="zero divide";                                              break;
      case 4014: error_string="unknown command";                                          break;
      case 4015: error_string="wrong jump (never generated error)";                       break;
      case 4016: error_string="not initialized array";                                    break;
      case 4017: error_string="dll calls are not allowed";                                break;
      case 4018: error_string="cannot load library";                                      break;
      case 4019: error_string="cannot call function";                                     break;
      case 4020: error_string="expert function calls are not allowed";                    break;
      case 4021: error_string="not enough memory for temp string returned from function"; break;
      case 4022: error_string="system is busy (never generated error)";                   break;
      case 4050: error_string="invalid function parameters count";                        break;
      case 4051: error_string="invalid function parameter value";                         break;
      case 4052: error_string="string function internal error";                           break;
      case 4053: error_string="some array error";                                         break;
      case 4054: error_string="incorrect series array using";                             break;
      case 4055: error_string="custom indicator error";                                   break;
      case 4056: error_string="arrays are incompatible";                                  break;
      case 4057: error_string="global variables processing error";                        break;
      case 4058: error_string="global variable not found";                                break;
      case 4059: error_string="function is not allowed in testing mode";                  break;
      case 4060: error_string="function is not confirmed";                                break;
      case 4061: error_string="send mail error";                                          break;
      case 4062: error_string="string parameter expected";                                break;
      case 4063: error_string="integer parameter expected";                               break;
      case 4064: error_string="double parameter expected";                                break;
      case 4065: error_string="array as parameter expected";                              break;
      case 4066: error_string="requested history data in update state";                   break;
      case 4099: error_string="end of file";                                              break;
      case 4100: error_string="some file error";                                          break;
      case 4101: error_string="wrong file name";                                          break;
      case 4102: error_string="too many opened files";                                    break;
      case 4103: error_string="cannot open file";                                         break;
      case 4104: error_string="incompatible access to a file";                            break;
      case 4105: error_string="no order selected";                                        break;
      case 4106: error_string="unknown symbol";                                           break;
      case 4107: error_string="invalid price parameter for trade function";               break;
      case 4108: error_string="invalid ticket";                                           break;
      case 4109: error_string="trade is not allowed in the expert properties";            break;
      case 4110: error_string="longs are not allowed in the expert properties";           break;
      case 4111: error_string="shorts are not allowed in the expert properties";          break;
      case 4200: error_string="object is already exist";                                  break;
      case 4201: error_string="unknown object property";                                  break;
      case 4202: error_string="object is not exist";                                      break;
      case 4203: error_string="unknown object type";                                      break;
      case 4204: error_string="no object name";                                           break;
      case 4205: error_string="object coordinates error";                                 break;
      case 4206: error_string="no specified subwindow";                                   break;
      default:   error_string="unknown error";
     }
//----
   return(error_string);
  }
//+------------------------------------------------------------------+
//| convert red, green and blue values to color                      |
//+------------------------------------------------------------------+
int RGB(int red_value,int green_value,int blue_value)
  {
//---- check parameters
   if(red_value<0)     red_value=0;
   if(red_value>255)   red_value=255;
   if(green_value<0)   green_value=0;
   if(green_value>255) green_value=255;
   if(blue_value<0)    blue_value=0;
   if(blue_value>255)  blue_value=255;
//----
   green_value<<=8;
   blue_value<<=16;
   return(red_value+green_value+blue_value);
  }
//+------------------------------------------------------------------+
//| right comparison of 2 doubles                                    |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2)
  {
   if(NormalizeDouble(number1-number2,8)==0) return(true);
   else return(false);
  }
//+------------------------------------------------------------------+
//| up to 16 digits after decimal point                              |
//+------------------------------------------------------------------+
string DoubleToStrMorePrecision(double number,int precision)
  {
   double rem,integer,integer2;
   double DecimalArray[17]={ 1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0,  10000000.0, 100000000.0,
                             1000000000.0, 10000000000.0, 100000000000.0, 10000000000000.0, 100000000000000.0,
                             1000000000000000.0, 1000000000000000.0, 10000000000000000.0 };
   string intstring,remstring,retstring;
   bool   isnegative=false;
   int    rem2;
//----
   if(precision<0)  precision=0;
   if(precision>16) precision=16;
//----
   double p=DecimalArray[precision];
   if(number<0.0) { isnegative=true; number=-number; }
   integer=MathFloor(number);
   rem=MathRound((number-integer)*p);
   remstring="";
   for(int i=0; i<precision; i++)
     {
      integer2=MathFloor(rem/10);
      rem2=NormalizeDouble(rem-integer2*10,0);
      remstring=rem2+remstring;
      rem=integer2;
     }
//----
   intstring=DoubleToStr(integer,0);
   if(isnegative) retstring="-"+intstring;
   else           retstring=intstring;
   if(precision>0) retstring=retstring+"."+remstring;
   return(retstring);
  }
//+------------------------------------------------------------------+
//| convert integer to string contained input's hexadecimal notation |
//+------------------------------------------------------------------+
string IntegerToHexString(int integer_number)
  {
   string hex_string="00000000";
   int    value, shift=28;
//   Print("Parameter for IntegerHexToString is ",integer_number);
//----
   for(int i=0; i<8; i++)
     {
      value=(integer_number>>shift)&0x0F;
      if(value<10) hex_string=StringSetChar(hex_string, i, value+'0');
      else         hex_string=StringSetChar(hex_string, i, (value-10)+'A');
      shift-=4;
     }
//----
   return(hex_string);
  }
//+------------------------------------------------------------------+
/**
 * function that is called on init
 */
void customInit() {
}
/**
 * function that is called on start. If it returns false, the processing will end.
 * You can use it for your own custom checks.
 */
bool customStart() {
   return(true);
}
