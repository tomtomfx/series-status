
var options = {debug: true, width: 200, height: 200};
var allImg = document.querySelectorAll('img#img_gallery');
// console.log('There are: '+allImg.length+' images');

for (var i=0; i<allImg.length; i++)
{
	var img = allImg[i];
	img.onload = function()
	{
		var processedImg = this;
		SmartCrop.crop(this, options, function(result)
		{
			// console.log('Processing: '+processedImg.src); 
			var crop = result.topCrop;
			var	canvas = $('<canvas>')[0];
			var ctx = canvas.getContext('2d');
			canvas.width = options.width;
			canvas.height = options.height;
			ctx.drawImage(processedImg, crop.x, crop.y, crop.width, crop.height, 0, 0, canvas.width, canvas.height);
			tempImg = new Image();
			tempImg.className = "img-responsive";
			tempImg.src = canvas.toDataURL();
			processedImg.parentNode.replaceChild(tempImg, processedImg);
		});
	}
}
