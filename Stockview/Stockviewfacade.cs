using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Stockprice
{
    class Stockviewfacade
    {
        IQuote yahooQuotes = new Yahoomanager();
        public List<Ticker> GetYahooQuotes()
        {
            string serviceUrl = System.Configuration.ConfigurationSettings.AppSettings["yahoo"];
            string symbol = System.Configuration.ConfigurationSettings.AppSettings["symbols"];
            yahooQuotes.Tick = int.Parse(System.Configuration.ConfigurationSettings.AppSettings["symbols"].ToString());
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            return yahooQuotes.GetQuote();
        }
    }
}
