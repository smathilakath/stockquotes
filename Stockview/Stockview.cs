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
        
        public Stockview()
        {
            InitializeComponent();
        }
        private void Form1_Load(object sender, EventArgs e)
        {
            TestLoad();
        }
        private void TestLoad()
        {
            StartStockMonitoring();
        }

        private void UpdateDataGrid()
        {
            dataGridView1.DataSource = GetQuote("YHOO");
            RowColour();
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

                    await Task.Delay(5000);
                }
            }, TaskCreationOptions.LongRunning);
        }
        private void RowColour()
        {
            for (int i = 0; i < dataGridView1.Rows.Count; i++)
            {
                float change = float.Parse(dataGridView1.Rows[i].Cells["Change"].Value.ToString());
                if (change < 0)// Or your condition 
                {
                    dataGridView1.Rows[i].Cells["Change"].Style.ForeColor = Color.Red;
                }
                else
                {
                    dataGridView1.Rows[i].Cells["Change"].Style.ForeColor = Color.Green;
                }
            }
        }

        private List<Tickerview> GetQuote(string symbol)
        {
            Tickerview stockPrice = new Tickerview();
            stockPrice.StockPriceList = new List<Tickerview>();
            try
            {
                // Use Yahoo finance service to download stock data from Yahoo
                string yahooURL = @"http://download.finance.yahoo.com/d/quotes.csv?s=" + symbol + "&f=sl1d1t1c1hgvbap2";
                string[] symbols = symbol.Replace(",", " ").Split(' ');

                // Initialize a new WebRequest.
                HttpWebRequest webreq = (HttpWebRequest)WebRequest.Create(yahooURL);
                // Get the response from the Internet resource.
                HttpWebResponse webresp = (HttpWebResponse)webreq.GetResponse();
                // Read the body of the response from the server.
                StreamReader strm = new StreamReader(webresp.GetResponseStream(), Encoding.ASCII);
                string content = strm.ReadLine().Replace("\"", "");
                string[] contents = content.ToString().Split(',');
                stockPrice.Symbol = contents[0];
                stockPrice.Last = contents[1];
                stockPrice.Date = contents[2];
                stockPrice.Time = contents[3];
                stockPrice.Change = contents[4];
                stockPrice.High = contents[5];
                stockPrice.Low = contents[6];
                stockPrice.Volume = contents[7];
                stockPrice.Bid = contents[8];
                stockPrice.Ask = contents[9];
                stockPrice.StockPriceList.Add(stockPrice);
                strm.Close();
            }
            catch
            {
                // Handle exceptions.
            }
            return stockPrice.StockPriceList;
        }
    }
}
