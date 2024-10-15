# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.transaction do
	Satisfaction.create(
		category: "شغل",
		question: "کار من کار حرفه ای و جذاب است و به همین دلیل برایم خیلی جالب است"
		)
	Satisfaction.create(
		category: "شغل",
		question: "کار من کاری مفید و سودمند برای شرکت و جامعه است"
		)
	Satisfaction.create(
		category: "شغل",
		question: "کار من تالش برانگیز و خشنود کننده است"
		)


	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "سرپرستم برای انجام کار با من مشورت می کند و در حیطه کاری به من آزادی عمل می دهد"
		)
	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "هر وقت بخواهم می توانم به سرپرستم )مافوقم( رجوع کنم و او همیشه در دسترس است"
		)
	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "سرپرستم کار خوب را تحسین و تشویق می کند"
		)
	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "سرپرستم فردی صمیمی و خوش قلب است و آداب معاشرت را رعایت می کند و حرمت زیردستان را نگه می دارد"
		)
	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "سرپرستم در جریان مسائل و اوضاع واحد خود قرار دارد و در کارش خبره، ماهر و باهوش است"
		)
	Satisfaction.create(
		category: "سرپرست/مافوق",
		question: "سرپرستم وقتی کاری را به من می سپارد آن را به روشنی شرح می دهد"
		)


	Satisfaction.create(
		category: "حقوق",
		question: "حقوق ماهیانه ام معادل استحقاق من بوده و منصفانه است"
		)
	Satisfaction.create(
		category: "حقوق",
		question: "حقوق ماهیانه ام متناسب با تالش و زحمت من است"
		)
	Satisfaction.create(
		category: "حقوق",
		question: "حقوق دریافتی ام برای پرداخت مخارج عادی زندگی ام کافیست"
		)
	Satisfaction.create(
		category: "حقوق",
		question: "حقوق ماهیانه ام با توجه به بودجه و امکانات سازمانم سهم عادالنه ای است"
		)
	Satisfaction.create(
		category: "حقوق",
		question: "حقوق و مزایای دریافتی من به خوبی سازمان های مشابه می باشد"
		)
	Satisfaction.create(
		category: "حقوق",
		question: "سازمانم دارای سیستم پرداخت خوبی برای کارکنان میباشد و منافع کافی به کارکنان می رساند"
		)


	Satisfaction.create(
		category: "همکاران",
		question: "همکارانم احساس مسئولیت دارند و فعال و سخت کوش هستند"
		)
	Satisfaction.create(
		category: "همکاران",
		question: " همکارانم افرادی سازگار و خوش خلق اند"
		)
	Satisfaction.create(
		category: "همکاران",
		question: "همکارانم انسان های بلندنظر، باگذشت، امین، راز نگهدار و فادار و مورد اعتمادند"
		)
	Satisfaction.create(
		category: "همکاران",
		question: "همکارانم افرادی حرفه ای، و صمیمی هستند"
		)
	Satisfaction.create(
		category: "همکاران",
		question: "همکارانم مشوق هستند و در من انگیزه کار ایجاد می کنند"
		)


	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "شغلم موجب افزایش دانش و تخصص من می شود"
		)
	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "در شغل من ترفیعات و ارتقاء را بر حسب قابلیت و توانایی کارکنان به آنان می دهند"
		)
	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "خط مشی و سیاستهای ارتقا و انتصاب عادالنه و منصفانه است"
		)
	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "جایگاه شغلی ام متناسب با شایستگی ها و قابلیتهایم است"
		)
	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "اگر کارکنان به خوبی به وظایفشان عمل کنند ترفیعات به طور منظم داده می شود"
		)
	Satisfaction.create(
		category: "قابلیت ارتقاء",
		question: "در شغل من امکان پیشرفت، رشد و ترفیع نسبتا مطلوب است"
		)


	Satisfaction.create(
		category: "ارگونومی",
		question: "فضای کار و اتاق کاری من مناسب است"
		)
	Satisfaction.create(
		category: "ارگونومی",
		question: "محیط کاری من، از نظر سر و صدا مناسب است"
		)
	Satisfaction.create(
		category: "ارگونومی",
		question: " محیط کاری من، از نور و تهویه مناسبی برخوردار است"
		)
	Satisfaction.create(
		category: "ارگونومی",
		question: "ساختمان مورد استفاده آسانسور، راهروها، فضای رستوران و ...( از کیفیت مناسبی برخوردار است"
		)



	Satisfaction.create(
		category: "ماندگاری",
		question: "احساس وابستگی عاطفی نسبت به سازمانم، دارم"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "بسیار خوشحال می شوم تا مابقی عمر شغلی خودم را در این سازمان بگذرانم"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "در حال حاضر، سازمانم را ترک نمی کنم، چراکه نسبت به افراد درون آن احساس تعلق دارم"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "در حال حاضر ترک این سازمان، مشکالت خانوادگی زیادی در زندگی ام ایجاد می نماید"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "رک این سازمان در شرایط فعلی از لحاظ اقتصادی برایم بسیار پرهزینه می باشد"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "اگر یک شغل بهتر در سازمانی دیگر به من پیشنهاد شود احساس میکنم درست نیست که آن را بپذیرم"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "به نظر من وفاداری به سازمان یک ارزش است و رفتن از این سازمان به سازمان دیگر کار درستی نیست"
		)
	Satisfaction.create(
		category: "ماندگاری",
		question: "بعضی وقت ها به فکر کار کردن در سازمان ها /شرکت های دیگر می افتم"
		)



	Satisfaction.create(
		category: "سلامت روان",
		question: "در شش ماه گذشته سرحال بوده و کامال احساس بهبودی و تندرستی می کنم"
		)
	Satisfaction.create(
		category: "سلامت روان",
		question: "در شش ماه گذشته احساس ضعف، بی حالی و بی رمقى بیماری و مریض حالی داشته ام"
		)
	Satisfaction.create(
		category: "سلامت روان",
		question: "در ماه های اخیر بر اثر نگرانی و دلشوره مشکل خواب زدگی یا مشکل به خواب رفتن داشته ام"
		)
	Satisfaction.create(
		category: "سلامت روان",
		question: "در ماه های اخیر احساس کرده ام که تحت استرس و فشار قرار دارم"
		)
	Satisfaction.create(
		category: "سلامت روان",
		question: "در شش ماه گذشته کارهایم را به خوبی انجام داده و از کیفیت و نحوه انجام کارهایم خشنود بوده ام"
		)
	Satisfaction.create(
		category: "سلامت روان",
		question: "تصمیم هایی که اخیرا گرفته ام به گونه ای بوده است که احساس مفید بودن، شایستگی و لیاقت بکنم"
		)






end
