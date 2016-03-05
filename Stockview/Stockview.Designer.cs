namespace Stockprice
{
    partial class Stockview
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.stockviewgrid = new System.Windows.Forms.DataGridView();
            ((System.ComponentModel.ISupportInitialize)(this.stockviewgrid)).BeginInit();
            this.SuspendLayout();
            // 
            // stockviewgrid
            // 
            this.stockviewgrid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.stockviewgrid.Location = new System.Drawing.Point(-2, 0);
            this.stockviewgrid.Name = "stockviewgrid";
            this.stockviewgrid.Size = new System.Drawing.Size(1043, 263);
            this.stockviewgrid.TabIndex = 0;
            // 
            // Stockview
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1042, 262);
            this.Controls.Add(this.stockviewgrid);
            this.MaximizeBox = false;
            this.Name = "Stockview";
            this.Text = "Stock View";
            this.Load += new System.EventHandler(this.Form1_Load);
            ((System.ComponentModel.ISupportInitialize)(this.stockviewgrid)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.DataGridView stockviewgrid;
    }
}

