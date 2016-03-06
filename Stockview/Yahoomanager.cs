using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace Stockprice
{
    class Yahoomanager : IQuote
    {
        private HttpWebRequest httpWebRequest = null;
        private HttpWebResponse httpWebResponse = null;
        private string serviceUrl = string.Empty;
        private int tick = 0;
        public void Setup()
        {
            httpWebRequest = (HttpWebRequest)WebRequest.Create(serviceUrl);
        }
        public List<Ticker> GetQuote()
        {
            Ticker tickerView = null;
            List<Ticker> tickerList = null;
            try
            {
                httpWebResponse = (HttpWebResponse)httpWebRequest.GetResponse();
                using (StreamReader streamReader = new StreamReader(httpWebResponse.GetResponseStream(), Encoding.ASCII))
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
                        tickerView.Change = string.Format("{0}({1})", tickDetails[4], tickDetails[10]);
                        tickerView.High = tickDetails[5];
                        tickerView.Low = tickDetails[6];
                        tickerView.Volume = tickDetails[7];
                        tickerView.Bid = tickDetails[8];
                        tickerView.Ask = tickDetails[9];
                        tickerList.Add(tickerView);
                    }
                };
            }
            catch (Exception ex)
            {
                Writelog(ex.Message);
            }
            return tickerList;
        }
        public void Writelog(string log)
        {
           //TODO: Need implementation.
        }
        
        public string Serviceurl
        {
            get { return serviceUrl; }
            set { serviceUrl = value; }
        }
    }
}
