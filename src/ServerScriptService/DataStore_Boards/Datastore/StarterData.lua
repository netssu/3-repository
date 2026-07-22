local module = {}

module.DonationData = {
	createInstance = true,
	data = {
		TotalDonation = 0,
		MonthlyTotalDonation = 0,
		LastDate = os.date("*t").month..os.date("*t").year,
		
	}
}

return module