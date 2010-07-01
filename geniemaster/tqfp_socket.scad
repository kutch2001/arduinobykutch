difference()
{
	cube([12.5,12.5,2.4], center = true);
	translate([ -5, -5, 0 ]) cube(size=[10.1,10.1,1.2]);
	translate([-5.7,-5.7,0.5]) cube(size=[11.4,11.4,0.7]);
	cylinder (h = 4, r1 = 2.5, r2 = 2.5, center = true, $fn = 20);
};
translate([-5,4.4,0]) rotate ([0,0,45]) cube([1,1,1]);
difference()
{
	translate ([-5.7,-5.7,0.5]) cube ([0.7,10.8,0.5]);
	for(i=[1:11])
		{
		translate ([-5.7,4.6-(i*0.8),0.5]) cube ([0.7,0.44,0.5]);
		}
};
difference()
{
	translate ([-5,-5.7,0.5]) cube ([10.7,0.7,0.5]);
	for(i=[1:11])
		{
		translate ([4.6-(i*0.8),-5.7,0.5]) cube ([0.44,0.7,0.5]);
		}
};
difference()
{
	translate ([-5.7,5.1,0.5]) cube ([10.9,0.7,0.5]);
	for(i=[1:11])
		{
		translate ([4.65-(i*0.8),5,0.5]) cube ([0.44,0.7,0.5]);
		}
};
difference()
{
	translate ([5.1,-5,0.5]) cube ([0.7,10.9,0.5]);
	for(i=[1:11])
		{
		translate ([5,4.65-(i*0.8),0.5]) cube ([0.7,0.44,0.5]);
		}
};
