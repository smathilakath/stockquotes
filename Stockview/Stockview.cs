using System;
using System.Drawing;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Stockprice
{
    public partial class Stockview : Form
    {
        private Stockviewfacade stockviewfacade = null;
        private int tickDelay;
        public Stockview()
        {
            tickDelay = int.Parse(System.Configuration.ConfigurationSettings.AppSettings["tick"]);
            InitializeComponent();
            stockviewfacade = new Stockviewfacade();
        }
        private void Form1_Load(object sender, EventArgs e)
        {
            StartStockMonitoring();
        }
        private void UpdateDataGridAsync()
        {
            stockviewgrid.DataSource = stockviewfacade.GetYahooQuotes();
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
                        UpdateDataGridAsync();
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
    }
}
