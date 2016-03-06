using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Stockprice
{
    public partial class Stockview : Form
    {
        private int tickDelay;
        public Stockview()
        {
            tickDelay = int.Parse(System.Configuration.ConfigurationSettings.AppSettings["tick"]);
            InitializeComponent();
        }
        private void Form1_Load(object sender, EventArgs e)
        {
            //TestLoad();
            stockviewgrid.DataSource = GetQuote();
            ChangeColour();

        }
        private void TestLoad()
        {
            StartStockMonitoring();
        }

        private void UpdateDataGrid()
        {
            stockviewgrid.DataSource = GetQuote();
            ChangeColour();
        }
        private void StartStockMonitoring()
        {
            Task stockMonitoringTask = Task.Factory.StartNew(async () =>
            {
                while (true)
                {
                    Invoke((Action)(() =>
                    {
                        UpdateDataGrid();
                    }));

                    await Task.Delay(tickDelay);
                }
            }, TaskCreationOptions.LongRunning);
        }
        private void ChangeColour()
        {
            for (int i = 0; i < stockviewgrid.Rows.Count; i++)
            {
                var strValue = stockviewgrid.Rows[i].Cells["Change"].Value.ToString();
                strValue = strValue.Substring(0, strValue.LastIndexOf("("));
                float change = float.Parse(strValue);
                if (change < 0)// Or your condition 
                {
                    stockviewgrid.Rows[i].Cells["Change"].Style.ForeColor = Color.Red;
                }
                else
                {
                    stockviewgrid.Rows[i].Cells["Change"].Style.ForeColor = Color.Green;
                }
            }
        }

        private List<Ticker> GetQuote()
        {
            Ticker tickerView = null;
            List<Ticker> tickerList =null;
            try
            {
                
                // Use Yahoo finance service to download stock data from Yahoo
                string symbol = System.Configuration.ConfigurationSettings.AppSettings["symbols"];
                string yahooURL = @"http://download.finance.yahoo.com/d/quotes.csv?s=" + symbol + "&f=sl1d1t1c1hgvbap2";
                // Initialize a new WebRequest.
                HttpWebRequest webreq = (HttpWebRequest)WebRequest.Create(yahooURL);
                // Get the response from the Internet resource.
                HttpWebResponse webresp = (HttpWebResponse)webreq.GetResponse();
                // Read the body of the response from the server.
                using (StreamReader streamReader = new StreamReader(webresp.GetResponseStream(), Encoding.ASCII))
                {
                    tickerList = new List<Ticker>();
                    while (!streamReader.EndOfStream)
                    {
                        tickerView = new Ticker();
                        string streamData = streamReader.ReadLine().Replace("\"", "");
                        string[] tickDetails = streamData.ToString().Split(',');
                        tickerView.Symbol = tickDetails[0];
                        tickerView.Last = tickDetails[1];
                        tickerView.Date = tickDetails[2];
                        tickerView.Time = tickDetails[3];
                        tickerView.Change = string.Format("{0}({1}%)", tickDetails[4], tickDetails[10]);
                        tickerView.High = tickDetails[5];
                        tickerView.Low = tickDetails[6];
                        tickerView.Volume = tickDetails[7];
                        tickerView.Bid = tickDetails[8];
                        tickerView.Ask = tickDetails[9];
                        tickerList.Add(tickerView);
                    }
                };
            }
            catch
            {
                // Handle exceptions.
            }
            return tickerList;
        }
    }
}
