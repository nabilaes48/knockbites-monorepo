// Order printing utility for kitchen/receipt printers
// Features unique KnockBites notification sound and enhanced receipt printing

export interface PrintableOrder {
  id: string;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  customerId?: string;
  items: {
    name: string;
    quantity: number;
    price: number;
    customizations?: string[];
    notes?: string;
  }[];
  subtotal: number;
  tax: number;
  total: number;
  specialInstructions?: string;
  createdAt: string;
  storeName?: string;
  couponCode?: string;
  couponDiscount?: number;
  isRepeatCustomer?: boolean;
}

/**
 * Generate printable HTML for an order receipt
 */
export function generateOrderReceiptHTML(order: PrintableOrder): string {
  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const itemsHTML = order.items.map(item => {
    let itemHTML = `
      <div class="item">
        <div class="item-row">
          <span class="qty">${item.quantity}x</span>
          <span class="name">${item.name}</span>
          <span class="price">$${(item.price * item.quantity).toFixed(2)}</span>
        </div>`;

    // Add customizations if any
    if (item.customizations && item.customizations.length > 0) {
      itemHTML += `
        <div class="customizations">
          ${item.customizations.map(c => `<span class="custom">- ${c}</span>`).join('')}
        </div>`;
    }

    // Add item notes if any
    if (item.notes) {
      itemHTML += `
        <div class="item-notes">
          <span class="note-label">Note:</span> ${item.notes}
        </div>`;
    }

    itemHTML += '</div>';
    return itemHTML;
  }).join('');

  // Generate welcome message based on customer
  const welcomeMessage = order.isRepeatCustomer
    ? `Welcome back, ${order.customerName.split(' ')[0]}! We're delighted to serve you again.`
    : `Welcome, ${order.customerName.split(' ')[0]}! Thank you for choosing ${order.storeName || 'KnockBites'}.`;

  // Generate coupon section if available
  const couponSection = order.couponCode ? `
    <div class="coupon-section">
      <div class="coupon-header">🎉 SPECIAL OFFER</div>
      <div class="coupon-code">Use code: ${order.couponCode}</div>
      <div class="coupon-details">Save ${order.couponDiscount ? `$${order.couponDiscount.toFixed(2)}` : '10%'} on your next order!</div>
    </div>
  ` : '';

  return `
<!DOCTYPE html>
<html>
<head>
  <title>Order #${order.orderNumber}</title>
  <style>
    @media print {
      @page {
        size: 80mm auto;
        margin: 0;
      }
      body {
        width: 80mm;
      }
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Courier New', monospace;
      font-size: 12px;
      line-height: 1.4;
      padding: 10px;
      max-width: 80mm;
    }

    .header {
      text-align: center;
      border-bottom: 2px dashed #000;
      padding-bottom: 10px;
      margin-bottom: 10px;
    }

    .store-name {
      font-size: 18px;
      font-weight: bold;
      margin-bottom: 5px;
    }

    .order-number {
      font-size: 24px;
      font-weight: bold;
      background: #000;
      color: #fff;
      padding: 8px;
      margin: 10px 0;
    }

    .order-time {
      font-size: 14px;
      margin-top: 5px;
    }

    .welcome-message {
      text-align: center;
      font-size: 13px;
      font-style: italic;
      padding: 8px;
      margin: 10px 0;
      background: #f8f8f8;
      border-radius: 4px;
    }

    .customer-info {
      border-bottom: 1px dashed #000;
      padding-bottom: 10px;
      margin-bottom: 10px;
    }

    .customer-name {
      font-size: 16px;
      font-weight: bold;
    }

    .customer-id {
      font-size: 10px;
      color: #666;
    }

    .customer-contact {
      font-size: 11px;
      color: #333;
    }

    .items {
      margin-bottom: 10px;
    }

    .items-header {
      font-weight: bold;
      font-size: 13px;
      text-transform: uppercase;
      margin-bottom: 8px;
      border-bottom: 1px solid #ccc;
      padding-bottom: 4px;
    }

    .item {
      margin-bottom: 8px;
      padding-bottom: 8px;
      border-bottom: 1px dotted #ccc;
    }

    .item:last-child {
      border-bottom: none;
    }

    .item-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
    }

    .qty {
      font-weight: bold;
      min-width: 30px;
    }

    .name {
      flex: 1;
      font-weight: bold;
    }

    .price {
      text-align: right;
      min-width: 50px;
    }

    .customizations {
      margin-left: 30px;
      margin-top: 4px;
      font-size: 11px;
    }

    .custom {
      display: block;
      color: #444;
      font-style: italic;
    }

    .item-notes {
      margin-left: 30px;
      margin-top: 4px;
      font-size: 11px;
      background: #f0f0f0;
      padding: 4px;
      border-radius: 2px;
    }

    .note-label {
      font-weight: bold;
    }

    .special-instructions {
      background: #fff3cd;
      border: 2px solid #ffc107;
      padding: 10px;
      margin: 10px 0;
      font-size: 14px;
    }

    .special-instructions-label {
      font-weight: bold;
      font-size: 12px;
      text-transform: uppercase;
      margin-bottom: 5px;
      display: block;
    }

    .totals {
      border-top: 2px dashed #000;
      padding-top: 10px;
      margin-top: 10px;
    }

    .total-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 4px;
    }

    .total-row.grand-total {
      font-size: 18px;
      font-weight: bold;
      border-top: 1px solid #000;
      padding-top: 8px;
      margin-top: 8px;
    }

    .coupon-section {
      text-align: center;
      border: 2px dashed #28a745;
      padding: 10px;
      margin: 15px 0;
      background: #d4edda;
    }

    .coupon-header {
      font-weight: bold;
      font-size: 14px;
      margin-bottom: 5px;
    }

    .coupon-code {
      font-family: monospace;
      font-size: 16px;
      font-weight: bold;
      background: #fff;
      padding: 5px 10px;
      margin: 5px 0;
      display: inline-block;
    }

    .coupon-details {
      font-size: 11px;
      color: #155724;
    }

    .footer {
      text-align: center;
      border-top: 2px dashed #000;
      padding-top: 10px;
      margin-top: 15px;
      font-size: 10px;
    }

    .thank-you {
      font-size: 14px;
      font-weight: bold;
      margin-bottom: 5px;
    }

    .footer-message {
      font-size: 11px;
      margin-bottom: 5px;
    }

    .print-time {
      font-size: 9px;
      color: #666;
      margin-top: 5px;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="store-name">${order.storeName || 'KnockBites'}</div>
    <div class="order-number">ORDER #${order.orderNumber}</div>
    <div class="order-time">${formatDate(order.createdAt)} at ${formatTime(order.createdAt)}</div>
  </div>

  <div class="welcome-message">
    ${welcomeMessage}
  </div>

  <div class="customer-info">
    <div class="customer-name">${order.customerName}</div>
    ${order.customerId ? `<div class="customer-id">Customer ID: ${order.customerId.substring(0, 8).toUpperCase()}</div>` : ''}
    <div class="customer-contact">${order.customerPhone}</div>
    ${order.customerEmail ? `<div class="customer-contact">${order.customerEmail}</div>` : ''}
  </div>

  <div class="items">
    <div class="items-header">Order Items</div>
    ${itemsHTML}
  </div>

  ${order.specialInstructions ? `
    <div class="special-instructions">
      <span class="special-instructions-label">Special Instructions:</span>
      ${order.specialInstructions}
    </div>
  ` : ''}

  <div class="totals">
    <div class="total-row">
      <span>Subtotal:</span>
      <span>$${order.subtotal.toFixed(2)}</span>
    </div>
    <div class="total-row">
      <span>Tax:</span>
      <span>$${order.tax.toFixed(2)}</span>
    </div>
    <div class="total-row grand-total">
      <span>TOTAL:</span>
      <span>$${order.total.toFixed(2)}</span>
    </div>
  </div>

  ${couponSection}

  <div class="footer">
    <div class="thank-you">Thank you for your order!</div>
    <div class="footer-message">We appreciate your business. See you again soon!</div>
    <div class="print-time">Printed: ${new Date().toLocaleString()}</div>
  </div>
</body>
</html>
  `;
}

/**
 * Print an order using a new window
 */
export function printOrder(order: PrintableOrder): void {
  const printContent = generateOrderReceiptHTML(order);

  const printWindow = window.open('', '_blank', 'width=400,height=600');
  if (!printWindow) {
    console.error('Failed to open print window. Pop-up may be blocked.');
    return;
  }

  printWindow.document.write(printContent);
  printWindow.document.close();

  // Wait for content to load, then print
  printWindow.onload = () => {
    printWindow.focus();
    printWindow.print();
    // Close the window after printing (or if cancelled)
    setTimeout(() => {
      printWindow.close();
    }, 1000);
  };
}

/**
 * Auto-print an order (used for new order notifications)
 */
export function autoPrintOrder(order: PrintableOrder): void {
  // Check if auto-print is enabled in localStorage
  const autoPrintEnabled = localStorage.getItem('autoPrintOrders') !== 'false';

  if (autoPrintEnabled) {
    printOrder(order);
  }
}

// KnockBites signature melody frequencies (musical notes)
// Pattern: "Knock-Bites!" - ascending cheerful melody (same as iOS)
const KNOCKBITES_MELODY = [
  { frequency: 659.25, duration: 0.12 },  // E5 - "Knock"
  { frequency: 783.99, duration: 0.12 },  // G5 - "-"
  { frequency: 880.00, duration: 0.15 },  // A5 - "Bites"
  { frequency: 1046.50, duration: 0.25 }, // C6 - "!" (high finish)
];

// Urgent order melody - for priority/rush orders
const URGENT_MELODY = [
  { frequency: 880.00, duration: 0.08 },  // A5 - Quick
  { frequency: 1046.50, duration: 0.08 }, // C6
  { frequency: 880.00, duration: 0.08 },  // A5
  { frequency: 1046.50, duration: 0.08 }, // C6
  { frequency: 1174.66, duration: 0.20 }, // D6 - Attention!
];

/**
 * Play a tone with envelope for pleasant sound
 */
function playToneWithEnvelope(
  audioContext: AudioContext,
  frequency: number,
  startTime: number,
  duration: number,
  volume: number = 0.5
): void {
  const oscillator = audioContext.createOscillator();
  const gainNode = audioContext.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(audioContext.destination);

  oscillator.frequency.value = frequency;
  oscillator.type = 'sine';

  // Attack-sustain-release envelope for pleasant sound
  const attackTime = 0.02;
  const releaseTime = 0.05;

  gainNode.gain.setValueAtTime(0, startTime);
  gainNode.gain.linearRampToValueAtTime(volume, startTime + attackTime);
  gainNode.gain.setValueAtTime(volume, startTime + duration - releaseTime);
  gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + duration);

  oscillator.start(startTime);
  oscillator.stop(startTime + duration);
}

/**
 * Play the unique KnockBites notification melody for new orders
 * This distinctive sound matches the iOS app for brand consistency
 */
export function playNewOrderSound(): void {
  try {
    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const audioContext = new AudioContextClass();

    const now = audioContext.currentTime;

    // Play KnockBites melody
    let offset = 0;
    KNOCKBITES_MELODY.forEach(note => {
      playToneWithEnvelope(audioContext, note.frequency, now + offset, note.duration, 0.5);
      offset += note.duration;
    });

    // Play melody twice for better recognition (like iOS)
    const totalDuration = KNOCKBITES_MELODY.reduce((sum, n) => sum + n.duration, 0);
    offset = totalDuration + 0.15;

    KNOCKBITES_MELODY.forEach(note => {
      playToneWithEnvelope(audioContext, note.frequency, now + offset, note.duration, 0.4);
      offset += note.duration;
    });

  } catch (error) {
    console.log('Audio notification not supported:', error);
  }
}

/**
 * Play urgent order sound - faster, more attention-grabbing
 */
export function playUrgentOrderSound(): void {
  try {
    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const audioContext = new AudioContextClass();

    const now = audioContext.currentTime;

    let offset = 0;
    URGENT_MELODY.forEach(note => {
      playToneWithEnvelope(audioContext, note.frequency, now + offset, note.duration, 0.6);
      offset += note.duration;
    });

  } catch (error) {
    console.log('Audio notification not supported:', error);
  }
}

/**
 * Play order ready sound - pleasant completion chime
 */
export function playOrderReadySound(): void {
  try {
    const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const audioContext = new AudioContextClass();

    const now = audioContext.currentTime;
    const readyMelody = [
      { frequency: 523.25, duration: 0.1 },  // C5
      { frequency: 659.25, duration: 0.1 },  // E5
      { frequency: 783.99, duration: 0.2 },  // G5 (sustained)
    ];

    let offset = 0;
    readyMelody.forEach(note => {
      playToneWithEnvelope(audioContext, note.frequency, now + offset, note.duration, 0.4);
      offset += note.duration;
    });

  } catch (error) {
    console.log('Audio notification not supported:', error);
  }
}

/**
 * Check if browser supports printing
 */
export function isPrintSupported(): boolean {
  return typeof window !== 'undefined' && typeof window.print === 'function';
}
