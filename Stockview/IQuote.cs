using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Stockview
{
    public interface IQuote
    {
        void Setup();
        List<Ticker> GetQuote();
        void Writelog(string log);
        string Serviceurl
        {
            get;
            set;
        }
       
    }
}
