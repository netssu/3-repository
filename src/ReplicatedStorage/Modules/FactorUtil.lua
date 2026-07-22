local factorModule = {}

--[[By @Thurzinx, 05/07/2025

What this module does?

R: Get a number between 0 ~ 1, and return in a factor that max value is 0.5
So if the number received is 0.5 then return 0, because 0.5 is the start to calculate
the value, heres a better representation:

Obs: If the value is higher than 1 then is set to 1 and the same thing happens
when the value is lower than 0.

Example Values:
x = 0.2
y = 0.6

0----------0.5----------1.0 // In the scale we are working on
			
			|
			|
			V
			
-0.5--------0-----------1.0 //So here 0.5 == 0
			
			|
			|
			V
			
x(0.2 --> -0.3)
y(0.7 --> 0.1)

-0.5--x-----0----y------1.0
]]

function factorModule.CalcFactor(x: number, changeOpt: boolean)
	if x > 0.5 then --// Positive value
		if x > 1 then
			x = 1
		end
		x = x - 0.5
	elseif x < 0.5 then --// Negative value (positive when changeOpt = true)
		if x < 0 then
			x = 0
		end
		x = x - 0.5
		if changeOpt then
			x = -x
		end
	elseif x == 0.5 then
		x = 0
	end
	
	return x
end

return factorModule