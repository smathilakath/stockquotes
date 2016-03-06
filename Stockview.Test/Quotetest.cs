using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Stockview.Test
{
    [TestClass]
    public class Quotetest
    {
        [TestMethod]
        public void TestQuoteGetCount()
        {
            IQuote yahooQuotes = new Yahoomanager();
            string serviceUrl = "http://download.finance.yahoo.com/d/quotes.csv?s={0}&amp;f=sl1d1t1c1hgvbap2";
            string symbol = "YHOO+GOOG+MSFT";
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            var result =  yahooQuotes.GetQuote();
            Assert.AreEqual(3, result.Count);
        }
        [TestMethod]
        public void TestQuoteGetSingle()
        {
            IQuote yahooQuotes = new Yahoomanager();
            string serviceUrl = "http://download.finance.yahoo.com/d/quotes.csv?s={0}&amp;f=sl1d1t1c1hgvbap2";
            string symbol = "YHOO";
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            var result = yahooQuotes.GetQuote();
            Assert.AreEqual(1, result.Count);
            Assert.AreEqual("YHOO", result[0].Symbol);
        }
        [TestMethod]
        public void TestQuoteGetSinglePrice()
        {
            IQuote yahooQuotes = new Yahoomanager();
            string serviceUrl = "http://download.finance.yahoo.com/d/quotes.csv?s={0}&amp;f=sl1d1t1c1hgvbap2";
            string symbol = "YHOO";
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            var result = yahooQuotes.GetQuote();
            //string compare
            Assert.AreEqual("22946594", result[0].Volume);
            //string fail
            //Assert.AreEqual(22946594, result[0].Volume);
            Assert.AreEqual("33.70", result[0].Ask);
            Assert.AreEqual("33.55", result[0].Bid);
            Assert.AreEqual("33.93", result[0].High);
            Assert.AreEqual("33.86", result[0].Last);
            Assert.AreEqual("32.76", result[0].Low);
        }
        [TestMethod]
        public void TestQuoteGetChange()
        {
            IQuote yahooQuotes = new Yahoomanager();
            string serviceUrl = "http://download.finance.yahoo.com/d/quotes.csv?s={0}&amp;f=sl1d1t1c1hgvbap2";
            string symbol = "YHOO+GOOG+MSFT";
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            var result = yahooQuotes.GetQuote();
            Assert.AreEqual(3, result.Count);
        }
        [TestMethod]
        public void TestQuoteGetLastChange()
        {
            IQuote yahooQuotes = new Yahoomanager();
            string serviceUrl = "http://download.finance.yahoo.com/d/quotes.csv?s={0}&amp;f=sl1d1t1c1hgvbap2";
            string symbol = "YHOO+GOOG+MSFT";
            yahooQuotes.Serviceurl = string.Format(serviceUrl, symbol);
            yahooQuotes.Setup();
            var result = yahooQuotes.GetQuote();
            Assert.AreEqual(3, result.Count);
        }
    }
}
