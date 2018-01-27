w_pipe <- if(test3[2,4] != 0) {test3[2,4]} else 
			{sum(test3[3:4,4])}
			
w_imp <- sum(
			ifelse(sum(test3[5:6,22]) == 0, 
			  ifelse(test3[1,22] == 0, 0, (test3[1,22] - w_pipe)),
			  sum(test3[5:6,22])),
			  
			test3[c(22,30,42,54),22],
			
			ifelse(test3[51,22] == 0, 
			  ifelse(test3[50,22] == 0, 0, (test3[50,22] - test3[52,22])),
			  test3[51,22]),
			  
			ifelse(test3[64,22] == 0, sum(test3[65:66,22]), test3[64,22])
			)
			
w_unimp <- sum(
			  ifelse(test3[34,22] == 0, 
			    ifelse(test3[26,22] == 0, 0, (test3[26,22] - test3[30,22])),
				test[34,22]),

			  ifelse(test3[46,22] == 0, 
			    ifelse(test3[38,22] == 0, 0, (test3[38,22] - test3[42,22])),
				test[46,22]),
			
			  test3[52,22],
			  
			  ifelse(test3[67,22] == 0, sum(test3[68:69,22]), test3[67,22])
			  )

w_surface <- if(test3[56,4] != 0) {test3[56,4]} else 
			{sum(test3[57:63,4])}
			   
			
			
			