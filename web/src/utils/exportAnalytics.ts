// Analytics Export Utilities - CSV and PDF generation

interface ExportData {
  metrics?: {
    total_revenue: number;
    total_orders: number;
    avg_order_value: number;
    unique_customers: number;
  };
  revenueData?: Array<{
    time_label: string;
    revenue: number;
    orders: number;
  }>;
  popularItems?: Array<{
    item_name: string;
    times_ordered: number;
    total_revenue: number;
  }>;
  categoryDistribution?: Array<{
    category: string;
    count: number;
  }>;
  topCustomers?: Array<{
    customer_name: string;
    total_spent: number;
    total_orders: number;
  }>;
  dayOfWeekStats?: Array<{
    day_name: string;
    order_count: number;
    total_revenue: number;
  }>;
  dateRange: string;
  storeName: string;
}

// Convert data to CSV format
export const generateCSV = (data: ExportData, reportType: string): string => {
  const lines: string[] = [];
  const timestamp = new Date().toISOString().split("T")[0];

  lines.push(`KnockBites Analytics Report`);
  lines.push(`Generated: ${new Date().toLocaleDateString()}`);
  lines.push(`Store: ${data.storeName}`);
  lines.push(`Date Range: ${data.dateRange}`);
  lines.push(`Report Type: ${reportType}`);
  lines.push("");

  switch (reportType) {
    case "summary":
      lines.push("SUMMARY METRICS");
      lines.push("Metric,Value");
      lines.push(`Total Revenue,$${data.metrics?.total_revenue?.toFixed(2) || 0}`);
      lines.push(`Total Orders,${data.metrics?.total_orders || 0}`);
      lines.push(`Average Order Value,$${data.metrics?.avg_order_value?.toFixed(2) || 0}`);
      lines.push(`Unique Customers,${data.metrics?.unique_customers || 0}`);
      break;

    case "revenue":
      lines.push("REVENUE DATA");
      lines.push("Period,Revenue,Orders");
      data.revenueData?.forEach((row) => {
        lines.push(`${row.time_label},$${Number(row.revenue).toFixed(2)},${row.orders}`);
      });
      break;

    case "items":
      lines.push("ITEM PERFORMANCE");
      lines.push("Item Name,Times Ordered,Total Revenue");
      data.popularItems?.forEach((item) => {
        lines.push(`"${item.item_name}",${item.times_ordered},$${Number(item.total_revenue).toFixed(2)}`);
      });
      break;

    case "customers":
      lines.push("TOP CUSTOMERS");
      lines.push("Customer Name,Total Spent,Total Orders");
      data.topCustomers?.forEach((customer) => {
        lines.push(`"${customer.customer_name}",$${customer.total_spent.toFixed(2)},${customer.total_orders}`);
      });
      break;

    case "dayOfWeek":
      lines.push("DAY OF WEEK ANALYSIS");
      lines.push("Day,Orders,Revenue");
      data.dayOfWeekStats?.forEach((day) => {
        lines.push(`${day.day_name},${day.order_count},$${Number(day.total_revenue).toFixed(2)}`);
      });
      break;

    case "full":
    default:
      // Full report with all sections
      lines.push("SUMMARY METRICS");
      lines.push("Metric,Value");
      lines.push(`Total Revenue,$${data.metrics?.total_revenue?.toFixed(2) || 0}`);
      lines.push(`Total Orders,${data.metrics?.total_orders || 0}`);
      lines.push(`Average Order Value,$${data.metrics?.avg_order_value?.toFixed(2) || 0}`);
      lines.push(`Unique Customers,${data.metrics?.unique_customers || 0}`);
      lines.push("");

      lines.push("REVENUE BY PERIOD");
      lines.push("Period,Revenue,Orders");
      data.revenueData?.forEach((row) => {
        lines.push(`${row.time_label},$${Number(row.revenue).toFixed(2)},${row.orders}`);
      });
      lines.push("");

      lines.push("TOP ITEMS");
      lines.push("Item Name,Times Ordered,Total Revenue");
      data.popularItems?.slice(0, 10).forEach((item) => {
        lines.push(`"${item.item_name}",${item.times_ordered},$${Number(item.total_revenue).toFixed(2)}`);
      });
      lines.push("");

      lines.push("TOP CUSTOMERS");
      lines.push("Customer Name,Total Spent,Total Orders");
      data.topCustomers?.slice(0, 10).forEach((customer) => {
        lines.push(`"${customer.customer_name}",$${customer.total_spent.toFixed(2)},${customer.total_orders}`);
      });
      lines.push("");

      lines.push("SALES BY DAY");
      lines.push("Day,Orders,Revenue");
      data.dayOfWeekStats?.forEach((day) => {
        lines.push(`${day.day_name},${day.order_count},$${Number(day.total_revenue).toFixed(2)}`);
      });
      break;
  }

  return lines.join("\n");
};

// Download CSV file
export const downloadCSV = (csvContent: string, filename: string): void => {
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", `${filename}.csv`);
  link.style.visibility = "hidden";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

// Generate PDF content (using browser print)
export const generatePDFContent = (data: ExportData): string => {
  const timestamp = new Date().toLocaleDateString();

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <title>KnockBites Analytics Report</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          padding: 40px;
          max-width: 800px;
          margin: 0 auto;
          color: #1a1a1a;
        }
        .header {
          text-align: center;
          border-bottom: 2px solid #2196F3;
          padding-bottom: 20px;
          margin-bottom: 30px;
        }
        .header h1 {
          color: #2196F3;
          margin: 0;
          font-size: 28px;
        }
        .header h2 {
          color: #FF8C42;
          margin: 10px 0 0;
          font-size: 18px;
          font-weight: normal;
        }
        .meta {
          display: flex;
          justify-content: space-between;
          color: #666;
          font-size: 12px;
          margin-top: 15px;
        }
        .section {
          margin-bottom: 30px;
        }
        .section h3 {
          color: #2196F3;
          border-bottom: 1px solid #e0e0e0;
          padding-bottom: 8px;
          margin-bottom: 15px;
          font-size: 16px;
        }
        .kpi-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 15px;
          margin-bottom: 30px;
        }
        .kpi-card {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 15px;
          text-align: center;
        }
        .kpi-card .label {
          color: #666;
          font-size: 12px;
          margin-bottom: 5px;
        }
        .kpi-card .value {
          font-size: 24px;
          font-weight: bold;
          color: #1a1a1a;
        }
        .kpi-card.revenue .value { color: #4CAF50; }
        .kpi-card.orders .value { color: #2196F3; }
        .kpi-card.avg .value { color: #9C27B0; }
        .kpi-card.customers .value { color: #FF8C42; }
        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 13px;
        }
        th {
          background: #f8f9fa;
          text-align: left;
          padding: 10px;
          font-weight: 600;
          color: #666;
          border-bottom: 2px solid #e0e0e0;
        }
        td {
          padding: 10px;
          border-bottom: 1px solid #e0e0e0;
        }
        tr:nth-child(even) {
          background: #fafafa;
        }
        .text-right {
          text-align: right;
        }
        .text-green {
          color: #4CAF50;
        }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #e0e0e0;
          text-align: center;
          color: #999;
          font-size: 11px;
        }
        @media print {
          body { padding: 20px; }
          .section { page-break-inside: avoid; }
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>KnockBites</h1>
        <h2>Analytics Report</h2>
        <div class="meta">
          <span>Store: ${data.storeName}</span>
          <span>Period: ${data.dateRange}</span>
          <span>Generated: ${timestamp}</span>
        </div>
      </div>

      <div class="kpi-grid">
        <div class="kpi-card revenue">
          <div class="label">Total Revenue</div>
          <div class="value">$${data.metrics?.total_revenue?.toFixed(2) || '0.00'}</div>
        </div>
        <div class="kpi-card orders">
          <div class="label">Total Orders</div>
          <div class="value">${data.metrics?.total_orders || 0}</div>
        </div>
        <div class="kpi-card avg">
          <div class="label">Avg Order Value</div>
          <div class="value">$${data.metrics?.avg_order_value?.toFixed(2) || '0.00'}</div>
        </div>
        <div class="kpi-card customers">
          <div class="label">Unique Customers</div>
          <div class="value">${data.metrics?.unique_customers || 0}</div>
        </div>
      </div>

      ${data.popularItems && data.popularItems.length > 0 ? `
      <div class="section">
        <h3>Top Performing Items</h3>
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Item Name</th>
              <th class="text-right">Orders</th>
              <th class="text-right">Revenue</th>
            </tr>
          </thead>
          <tbody>
            ${data.popularItems.slice(0, 10).map((item, i) => `
              <tr>
                <td>${i + 1}</td>
                <td>${item.item_name}</td>
                <td class="text-right">${item.times_ordered}</td>
                <td class="text-right text-green">$${Number(item.total_revenue).toFixed(2)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
      ` : ''}

      ${data.topCustomers && data.topCustomers.length > 0 ? `
      <div class="section">
        <h3>Top Customers</h3>
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Customer</th>
              <th class="text-right">Orders</th>
              <th class="text-right">Total Spent</th>
            </tr>
          </thead>
          <tbody>
            ${data.topCustomers.slice(0, 10).map((customer, i) => `
              <tr>
                <td>${i + 1}</td>
                <td>${customer.customer_name}</td>
                <td class="text-right">${customer.total_orders}</td>
                <td class="text-right text-green">$${customer.total_spent.toFixed(2)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
      ` : ''}

      ${data.dayOfWeekStats && data.dayOfWeekStats.length > 0 ? `
      <div class="section">
        <h3>Sales by Day of Week</h3>
        <table>
          <thead>
            <tr>
              <th>Day</th>
              <th class="text-right">Orders</th>
              <th class="text-right">Revenue</th>
            </tr>
          </thead>
          <tbody>
            ${data.dayOfWeekStats.map((day) => `
              <tr>
                <td>${day.day_name}</td>
                <td class="text-right">${day.order_count}</td>
                <td class="text-right text-green">$${Number(day.total_revenue).toFixed(2)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
      ` : ''}

      <div class="footer">
        <p>KnockBites - Business Analytics Platform</p>
        <p>© ${new Date().getFullYear()} KnockBites. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;
};

// Open PDF in new window for printing
export const downloadPDF = (data: ExportData): void => {
  const htmlContent = generatePDFContent(data);
  const printWindow = window.open("", "_blank");
  if (printWindow) {
    printWindow.document.write(htmlContent);
    printWindow.document.close();
    // Wait for content to load then trigger print
    printWindow.onload = () => {
      printWindow.print();
    };
  }
};

// Export both CSV and PDF options
export type ExportFormat = "csv" | "pdf";
export type ReportType = "summary" | "revenue" | "items" | "customers" | "dayOfWeek" | "full";

export const exportAnalytics = (
  format: ExportFormat,
  reportType: ReportType,
  data: ExportData
): void => {
  const timestamp = new Date().toISOString().split("T")[0];
  const filename = `knockbites-analytics-${reportType}-${timestamp}`;

  if (format === "csv") {
    const csvContent = generateCSV(data, reportType);
    downloadCSV(csvContent, filename);
  } else {
    downloadPDF(data);
  }
};
