using System;
using System.Drawing;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Stockview
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

        private void NotifyStock()
        {
            stockviewnotify.BalloonTipIcon = ToolTipIcon.Info;
            stockviewnotify.BalloonTipText = "Relax, I am monitoring your stocks";
            stockviewnotify.BalloonTipTitle = "Hit me, To know the status";
            stockviewnotify.Text = "Monitoring Stocks";
        }
        private void Form1_Load(object sender, EventArgs e)
        {
            NotifyStock();
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

        private void Stockview_Resize(object sender, EventArgs e)
        {
            if (FormWindowState.Minimized == this.WindowState)
            {
                stockviewnotify.Visible = true;
                stockviewnotify.ShowBalloonTip(500);
                this.Hide();
            }

            else if (FormWindowState.Normal == this.WindowState)
            {
                stockviewnotify.Visible = false;
                this.Show();
            }
        }

        private void stockviewnotify_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            this.Show();
            stockviewnotify.ShowBalloonTip(1000);
            WindowState = FormWindowState.Normal;
        }
    }
}
