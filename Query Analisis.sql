-- ==========================================================
-- PROJECT : Kimia Farma Business Performance Analysis
-- AUTHOR  : Nikolaus Marvin Liayasa
-- PURPOSE : Membuat tabel analisis utama berdasarkan hasil
--           agregasi dari empat tabel di BigQuery
--           (transaction, product, kantor_cabang, inventory)
-- DATASET : kimia_farma
-- TABLE   : kf_analisis
-- ==========================================================


-- Membuat (atau mengganti jika sudah ada) tabel analisis utama di BigQuery
CREATE OR REPLACE TABLE `rakamin-kf-analytics-476706.kimia_farma.kf_analisis` AS

-- Memilih kolom yang diperlukan dari tabel transaksi utama
SELECT
  -- ID unik untuk setiap transaksi
  ft.transaction_id,

  -- Tanggal transaksi dilakukan
  ft.date,

  -- Informasi cabang Kimia Farma tempat transaksi terjadi
  kc.branch_id,
  kc.branch_name,
  kc.kota,
  kc.provinsi,

  -- Rating cabang dari data kantor cabang
  kc.rating AS rating_cabang,

  -- Nama pelanggan yang melakukan transaksi
  ft.customer_name,

  -- Informasi produk yang dibeli
  ft.product_id,
  p.product_name,

  -- Harga produk aktual sebelum diskon
  ft.price AS actual_price,

  -- Persentase diskon yang diberikan untuk produk tersebut
  ft.discount_percentage,

  -- ==========================================================
  -- Hitung Persentase Laba Berdasarkan Harga Produk
  -- (mengikuti ketentuan dari instruksi tugas Rakamin)
  -- ==========================================================
  CASE
    WHEN ft.price <= 50000 THEN 0.10
    WHEN ft.price > 50000 AND ft.price <= 100000 THEN 0.15
    WHEN ft.price > 100000 AND ft.price <= 300000 THEN 0.20
    WHEN ft.price > 300000 AND ft.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS persentase_gross_laba,

  -- ==========================================================
  -- Hitung Harga Setelah Diskon (Nett Sales)
  -- Rumus: harga * (1 - diskon)
  -- Menggunakan IFNULL untuk mengganti nilai NULL diskon menjadi 0
  -- ==========================================================
  ft.price * (1 - IFNULL(ft.discount_percentage, 0)) AS nett_sales,

  -- ==========================================================
  -- Hitung Keuntungan Bersih (Nett Profit)
  -- Rumus: nett_sales * persentase_gross_laba
  -- ==========================================================
  (ft.price * (1 - IFNULL(ft.discount_percentage, 0))) *
  CASE
    WHEN ft.price <= 50000 THEN 0.10
    WHEN ft.price > 50000 AND ft.price <= 100000 THEN 0.15
    WHEN ft.price > 100000 AND ft.price <= 300000 THEN 0.20
    WHEN ft.price > 300000 AND ft.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS nett_profit,

  -- Rating transaksi dari pelanggan (berasal dari tabel transaksi)
  ft.rating AS rating_transaksi

-- ==========================================================
-- Sumber Data Utama: Tabel Transaksi
-- ==========================================================
FROM `rakamin-kf-analytics-476706.kimia_farma.kf_final_transaction` AS ft

-- ==========================================================
-- Join dengan Tabel Produk untuk menambahkan nama produk
-- ==========================================================
LEFT JOIN `rakamin-kf-analytics-476706.kimia_farma.kf_product` AS p
  ON ft.product_id = p.product_id

-- ==========================================================
-- Join dengan Tabel Kantor Cabang untuk menambahkan
-- informasi lokasi (kota, provinsi) dan rating cabang
-- ==========================================================
LEFT JOIN `rakamin-kf-analytics-476706.kimia_farma.kf_kantor_cabang` AS kc
  ON ft.branch_id = kc.branch_id;

-- ==========================================================
-- HASIL AKHIR:
-- Tabel kimia_farma.kf_analisis berisi kolom-kolom utama:
-- transaction_id, date, branch_name, kota, provinsi,
-- rating_cabang, customer_name, product_name, actual_price,
-- discount_percentage, persentase_gross_laba, nett_sales,
-- nett_profit, rating_transaksi.
--
-- Tabel ini siap digunakan untuk visualisasi di Google Looker Studio.
-- ==========================================================
