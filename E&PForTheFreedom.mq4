//+------------------------------------------------------------------+
//|                                             E&PForTheFreedom.mq4 |
//|                        Enrico & Pietro                           | 
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
input int    MovingPeriod  = 190;
input int    MovingShift   = 0;  //Changed to 0, we don't need the shift in this case.(??maybe after??)
int StopLoss = 30; //In our first strategy we can change this value to 30, then we need to change it. 
int TakeProfit = 100; //Same than before
int ticket = 0;
bool openedOrder = false;
double RSI_SELL = 56; //I have to insert the code for closing the positions opened without take profit. I can explain this passage in the next steps.
double RSI_BUY = 44;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
/*    Buy function,it gets Take Profit and Stop Loss as global parameters, please look at the beginning of this file */
void buy()
{     
      double vbid    = MarketInfo(Symbol(),MODE_BID);
      double TP_b = NormalizeDouble(vbid + Point * TakeProfit , Digits); 
      double SL_b = NormalizeDouble(vbid -  Point * StopLoss , Digits);
      double vask    = MarketInfo(Symbol(),MODE_ASK);             
      ticket = OrderSend(Symbol(), OP_BUY, 0.05, vask, 2, SL_b, TP_b, "Buy Order" , 0, 0 , clrGreen);
      if(ticket<0)
      {  openedOrder = True;
         Print("OrderSend failed with error #",GetLastError());
      }
      else
      {  
         Print("OrderSend placed successfully");
         Print("Hammer"); //My favourite pattern!This is not the case!(??maybe copy-paste??)
              
      }
}
/* Sell function,it gets Take Profit and Stop Loss as global parameters, please look at the beginning of this file */
void sell()
{
   double vbid    = MarketInfo(Symbol(),MODE_BID);
   double vask    = MarketInfo(Symbol(),MODE_ASK);
   double TP_s = NormalizeDouble(vask -  Point * TakeProfit , Digits);
   double SL_s = NormalizeDouble(vask +  Point * StopLoss , Digits); 
   ticket = OrderSend(Symbol(), OP_SELL, 0.05, vbid, 2, SL_s, TP_s, "Sell order" , 0 , 0 , clrRed);
   if(ticket<0)
   {
      Print("OrderSend failed with error #",GetLastError());
      Print("Hanging Man"); //Ahahahah Hanging man
                      
   }
   else
   {  
      Print("OrderSend placed successfully");
      openedOrder = True;
      Print("Hanging man");
              
   }
}
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      double ma;
      //--- go trading only for first tiks of new bar
      if(Volume[0] > 1) return;
      
      //--- get Moving Average 
       ma = iMA( NULL, 0, MovingPeriod, MovingShift, MODE_SMMA, PRICE_WEIGHTED, 0);
       
      //--- sell conditions
      /* Price cross up MA and RSI > RSI_SELL ====> SELL */
      if( Open[1] < ma && Close[1] > ma && iRSI(NULL, 0, 50, PRICE_WEIGHTED, 1) > RSI_SELL )
      {
          sell();
          return;
      }
//--- buy conditions
      /* Price cross down MA and RSI < 40 ====> RSI_BUY   */
      if( Open[1] > ma && Close[1] < ma && iRSI(NULL, 0, 50, PRICE_WEIGHTED, 1) < RSI_BUY)
      {
         buy();
         return;
      }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
