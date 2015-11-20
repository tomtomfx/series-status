/**
 * Tomtomfx theme for Highcharts JS
 * @author tomtomfx
 */

Highcharts.theme = {
	colors: ["#7798BF", "#55BF3B", "#DF5353", "#90ee7e", "#aaeeee", "#f7a35c", "#ff0066", "#7cb5ec", "#eeaaee","#55BF3B", "#7798BF", "#aaeeee"],
	chart: {
		backgroundColor: "#334A59",
		style: {
			fontFamily: "calibri"
		},
		borderColor: '#FFFFFF',
		borderRadius: 5,	
		borderWidth: 2,
		shadow: true,
		plotBackgroundColor: 'rgba(255, 255, 255, 1)',
		plotBorderColor: '#FFFFFF',
		plotBorderWidth: 1,
		plotShadow: false,
		marginRight: 30,
		marginTop: 35,
		marginBottom: 110,
	},
	plotOptions: {
		column: {
			borderColor: "#334A59",
			borderRadius: 3,
			borderWidth: 1
		},
		line: {
			
		},
	},
	title: {
		style: {
			color: "#FFFFFF",
			fontSize: '16px',
			fontWeight: 'bold'
		}
	},
	tooltip: {
		borderWidth: 2,
		backgroundColor: 'rgba(255, 255, 255, 0.75)',
		shadow: true,
		headerFormat: '<span style="font-size: 12px">{point.key}</span><br/>',
		pointFormat: '<span style="color:{series.color}">{series.name}: </span><b>{point.y}</b><br/>'
	},
	legend: {
		itemStyle: {
			color: "#FFFFFF",
			fontWeight: 'bold',
			fontSize: '13px'
		}
	},
	xAxis: {
		gridLineColor: '#E7E2D5',
		gridLineWidth: 1,
		title: {
			style: {
				color: "#FFFFFF",
				fontWeight: 'bold',
				textTransform: 'uppercase'
			}
		},
		labels: {
			style: {
				color: "#FFFFFF",
				fontSize: '12px'
			}
		}
	},
	yAxis: {
		gridLineColor: '#E7E2D5',
		minorTickInterval: 'auto',
		title: {
			style: {
				color: "#FFFFFF",
				fontWeight: 'bold',
				textTransform: 'uppercase'
			}
		},
		labels: {
			style: {
				color: "#FFFFFF",
				fontSize: '12px'
			}
		}
	},
	credits: {
		style: {
			color: '#FFFFFF'
		},
		position: {
			align: 'right',
			x: -20,
			verticalAlign: 'bottom',
			y: -15
		}
	},
};

// Apply the theme
Highcharts.setOptions(Highcharts.theme);
