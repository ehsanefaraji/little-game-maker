# بازی‌ساز کوچولو | Little Game Maker

یک پروژه Flutter آفلاین و فارسی برای ساخت و تجربه بازی‌های ساده کودکانه.

## نسخه آغازین
- صفحه اصلی فارسی
- چند بازی نمونه
- مینی‌گیم هزارتو با حرکت شخصیت و رسیدن به ستاره
- اجرای آفلاین

## ساخت نسخه اندروید
در GitHub Actions، گردش‌کار **Android Release APK** با هر Push به شاخه main یا با اجرای دستی فعال می‌شود.

چهار GitHub Actions Secret موردنیاز:
- `LITTLEGAMEMAKER_KEYSTORE_BASE64`
- `LITTLEGAMEMAKER_KEY_PASSWORD`
- `LITTLEGAMEMAKER_STORE_PASSWORD`
- `LITTLEGAMEMAKER_KEY_ALIAS`

خروجی در بخش Artifacts اجرای موفق با نام `little-game-maker-release-apk` قرار می‌گیرد.

> فایل keystore و رمزهای آن را هرگز در مخزن قرار ندهید.
