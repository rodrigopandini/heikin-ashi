//+------------------------------------------------------------------+
//|                                                   HeikinAshi.mq5 |
//|                                  Copyright 2016, Rodrigo Pandini |
//|                                         rodrigopandini@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Rodrigo Pandini"
#property link "rodrigopandini@gmail.com"
#property version "1.00"
#property description "Heikin-Ashi Candlesticks"
#property description "http://stockcharts.com/school/doku.php?id=chart_school:chart_analysis:heikin_ashi"

/*
Heikin-Ashi Candlesticks (http://stockcharts.com/school/doku.php?id=chart_school:chart_analysis:heikin_ashi)
-----------
1. The Heikin-Ashi Close is simply an average of the open,
high, low and close for the current period.

HA-Close = (Open(0) + High(0) + Low(0) + Close(0)) / 4

2. The Heikin-Ashi Open is the average of the prior Heikin-Ashi
candlestick open plus the close of the prior Heikin-Ashi candlestick.

HA-Open = (HA-Open(-1) + HA-Close(-1)) / 2

3. The Heikin-Ashi High is the maximum of three data points:
the current period's high, the current Heikin-Ashi
candlestick open or the current Heikin-Ashi candlestick close.

HA-High = Maximum of the High(0), HA-Open(0) or HA-Close(0)

4. The Heikin-Ashi low is the minimum of three data points:
the current period's low, the current Heikin-Ashi
candlestick open or the current Heikin-Ashi candlestick close.

HA-Low = Minimum of the Low(0), HA-Open(0) or HA-Close(0)


Obs:
The first Heikin-Ashi close equals the average of the open, high, low and close ((O+H+L+C)/4).
The first Heikin-Ashi open equals the average of the open and close ((O+C)/2).
The first Heikin-Ashi high equals the high and the first Heikin-Ashi low equals the low.


TODO:
  - colocar opção para desenhar no gráfico ao invés de subjanela.
  - colocar opção de HeikinAshi suavizado
  - conferir valores.
*/

// indicator is plotted in a separate window
#property indicator_separate_window
// indicator icon
//#property icon "../Images/heikin_ashi.ico"
// one graphic plot is used
#property indicator_plots 1
// 4 buffers for OHLC prices and 1 for the index of color
#property indicator_buffers 5
// specifying the labes for candles
#property indicator_label1 "Open;High;Low;Close"

// enum for type of chart
enum ChartType{
  Bars,
  Candles
};

// chart inputs
input ChartType InpChartType = 0; // Type of chart
input int InpLineWidthBarChart = 4; // Line width for bars
input color InpUpCandleColor = clrGreen; // Up candle color
input color InpDownCandleColor = clrRed; // Down candle color
input bool InpShowCurrentHLLeves = true; // Show current high/low levels
input color InpLevelsColor = clrGray; // Levels color
input ENUM_LINE_STYLE InpLevelsStyle = STYLE_DOT; // Levels style
input int InpLevelsWidth = 1; // Levels width

// global variables
int count = 0;

// arrays to store the OHLC prices and the index of color candles
double OpenBuffer[], HighBuffer[], LowBuffer[], CloseBuffer[], ColorIndexBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){
    // set arrays as indicator buffers
    SetIndexBuffer(0, OpenBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, HighBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, LowBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, CloseBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, ColorIndexBuffer, INDICATOR_COLOR_INDEX);

    // Assign the array with color indexes with the indicator's color indexes buffer
    PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
    // Set color for each index
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, InpUpCandleColor);
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, InpDownCandleColor);

    // indexation of arrays as timeseries
    ArraySetAsSeries(OpenBuffer, true);
    ArraySetAsSeries(HighBuffer, true);
    ArraySetAsSeries(LowBuffer, true);
    ArraySetAsSeries(CloseBuffer, true);
    ArraySetAsSeries(ColorIndexBuffer, true);

    // the null values should not be plotted
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
    PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
    PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);

    // verify the type of chart
    if(InpChartType == 0){ // bars
      // set the type of chart to color bars
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_BARS);
      // set the line drawing width for bars chart
      PlotIndexSetInteger(0, PLOT_LINE_WIDTH, InpLineWidthBarChart);
    }
    else
    if(InpChartType == 1){ // candles
      // set the type of chart to color candles
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_CANDLES);
    }
    else{
      return(INIT_PARAMETERS_INCORRECT);
    }

    // verify show levels
    if(InpShowCurrentHLLeves){
      // set the numbers of indicator leves
      IndicatorSetInteger(INDICATOR_LEVELS, 2);
      // set the colors of indicator levels
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, InpLevelsColor);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, InpLevelsColor);
      IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, InpLevelsStyle);
      IndicatorSetInteger(INDICATOR_LEVELSTYLE, 1, InpLevelsStyle);
      IndicatorSetInteger(INDICATOR_LEVELWIDTH, 0, InpLevelsWidth);
      IndicatorSetInteger(INDICATOR_LEVELWIDTH, 1, InpLevelsWidth);
    }

  //---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]){
//---

/*
  Print("Count: ", count, " o: ", open[rates_total - 1], " h: ", high[rates_total - 1],
        " l: ", low[rates_total - 1], " c: ", close[rates_total - 1]);
*/

  if(prev_calculated == 0){
    CloseBuffer[rates_total - 1] = (open[0] + high[0] + low[0] + close[0])/4;
    OpenBuffer[rates_total - 1] = (open[0] + close[0])/2;
    HighBuffer[rates_total - 1] = high[0];
    LowBuffer[rates_total - 1] = low[0];

    if(OpenBuffer[rates_total - 1] <= CloseBuffer[rates_total - 1])
      ColorIndexBuffer[rates_total - 1] = 0;
    else
      ColorIndexBuffer[rates_total - 1] = 1;

    for(int i = 1; i < rates_total; i++){
      CloseBuffer[rates_total - 1 - i] = (open[i] + high[i] + low[i] + close[i])/4;
      OpenBuffer[rates_total - 1 - i] = (OpenBuffer[rates_total - i] + CloseBuffer[rates_total - i])/2;
      HighBuffer[rates_total - 1 - i] = MathMax(MathMax(high[i], OpenBuffer[rates_total - i]), CloseBuffer[rates_total - i]);
      LowBuffer[rates_total - 1 - i] = MathMin(MathMin(low[i], OpenBuffer[rates_total - i]), CloseBuffer[rates_total - i]);

      if(OpenBuffer[rates_total - 1 - i] <= CloseBuffer[rates_total - 1 - i])
        ColorIndexBuffer[rates_total - 1 - i] = 0;
      else
        ColorIndexBuffer[rates_total - 1 - i] = 1;
    }
  }
  else{
    for(int i = prev_calculated; i < rates_total; i++){
      CloseBuffer[rates_total - 1 - i] = (open[i] + high[i] + low[i] + close[i])/4;
      OpenBuffer[rates_total - 1 - i] = (OpenBuffer[rates_total - i] + CloseBuffer[rates_total - i])/2;
      HighBuffer[rates_total - 1 - i] = MathMax(MathMax(high[i], OpenBuffer[rates_total - i]), CloseBuffer[rates_total - i]);
      LowBuffer[rates_total - 1 - i] = MathMin(MathMin(low[i], OpenBuffer[rates_total - i]), CloseBuffer[rates_total - i]);

      if(OpenBuffer[rates_total - 1 - i] <= CloseBuffer[rates_total - 1 - i])
        ColorIndexBuffer[rates_total - 1 - i] = 0;
      else
        ColorIndexBuffer[rates_total - 1 - i] = 1;
    }
  }

  //--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+
