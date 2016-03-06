using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Stockview
{
    /// <summary>
    /// Iquote act as an interface to follow mandatory parameters
    /// </summary>
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
