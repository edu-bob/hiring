# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use CronTable;

%::CronTable = (
				'table' => "cron",
				'heading' => "Cron",
				'columns' => [
					{
						'column' => "id",
						'heading' => "ID",
						'type' => "pk",
					},
					{
						'column' => "type",
						'heading' => "Schedule Type",
						'type' => "enum",
					},
					{
						'column' => "dow",
						'heading' => "Day of Week",
						'type' => "set",
						'labels' => [ "Sunday",
									"Monday",
									"Tuesday",
									"Wednesday",
									"Thursday",
									"Friday",
									"Saturday",
								],
					},
					{
						'column' => "dom",
						'heading' => "Day of Month",
						'type' => "bitvector",
						'labels' => \&CronTable::dom,
					},
					{
						'column' => "time",
						'heading' => "Time of Day",
						'type' => "bitvector",
						'labels' => [
							"12:00 midnight",
							"12:15 a.m.",
							"12:30 a.m.",
							"12:45 a.m.",
							"1:00 a.m.",
							"1:15 a.m.",
							"1:30 a.m.",
							"1:45 a.m.",
							"2:00 a.m.",
							"2:15 a.m.",
							"2:30 a.m.",
							"2:45 a.m.",
							"3:00 a.m.",
							"3:15 a.m.",
							"3:30 a.m.",
							"3:45 a.m.",
							"4:00 a.m.",
							"4:15 a.m.",
							"4:30 a.m.",
							"4:45 a.m.",
							"5:00 a.m.",
							"5:15 a.m.",
							"5:30 a.m.",
							"5:45 a.m.",
							"6:00 a.m.",
							"6:15 a.m.",
							"6:30 a.m.",
							"6:45 a.m.",
							"7:00 a.m.",
							"7:15 a.m.",
							"7:30 a.m.",
							"7:45 a.m.",
							"8:00 a.m.",
							"8:15 a.m.",
							"8:30 a.m.",
							"8:45 a.m.",
							"9:00 a.m.",
							"9:15 a.m.",
							"9:30 a.m.",
							"9:45 a.m.",
							"10:00 a.m.",
							"10:15 a.m.",
							"10:30 a.m.",
							"10:45 a.m.",
							"11:00 a.m.",
							"11:15 a.m.",
							"11:30 a.m.",
							"11:45 a.m.",
							"12:00 noon",
							"12:15 p.m.",
							"12:30 p.m.",
							"12:45 p.m.",
							"1:00 p.m.",
							"1:15 p.m.",
							"1:30 p.m.",
							"1:45 p.m.",
							"2:00 p.m.",
							"2:15 p.m.",
							"2:30 p.m.",
							"2:45 p.m.",
							"3:00 p.m.",
							"3:15 p.m.",
							"3:30 p.m.",
							"3:45 p.m.",
							"4:00 p.m.",
							"4:15 p.m.",
							"4:30 p.m.",
							"4:45 p.m.",
							"5:00 p.m.",
							"5:15 p.m.",
							"5:30 p.m.",
							"5:45 p.m.",
							"6:00 p.m.",
							"6:15 p.m.",
							"6:30 p.m.",
							"6:45 p.m.",
							"7:00 p.m.",
							"7:15 p.m.",
							"7:30 p.m.",
							"7:45 p.m.",
							"8:00 p.m.",
							"8:15 p.m.",
							"8:30 p.m.",
							"8:45 p.m.",
							"9:00 p.m.",
							"9:15 p.m.",
							"9:30 p.m.",
							"9:45 p.m.",
							"10:00 p.m.",
							"10:15 p.m.",
							"10:30 p.m.",
							"10:45 p.m.",
							"11:00 p.m.",
							"11:15 p.m.",
							"11:30 p.m.",
							"11:45 p.m.",
						],
					},
				],
				);

					
1;