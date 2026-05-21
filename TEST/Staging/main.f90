Program optimalStagedRocket
  use dataEntry
  implicit none
  integer i, sum
  real(8) res, get_optimal_mass, h, check
  real(8) n1, n2, n3
  real(8) mass_stage_1, mass_stage_2, mass_stage_3, mass_0
  real(8) mass_empty_stage_1, mass_empty_stage_2, mass_empty_stage_3
  real(8) mass_prop_stage_1, mass_prop_stage_2, mass_prop_stage_3

  call init_data()
  h=1.d-3
  res= 0.5d0
  do i=1, 50
     res = res - get_optimal_mass(res)*2*h/(get_optimal_mass(res+h)-get_optimal_mass(res-h))
  end do
  print*, res
  ! equation 11.87 Orbital mechanic Howard Curtis
  n1=(c1*res-1)/(c1*e1*res)
  n2=(c2*res-1)/(c2*e2*res)
  n3=(c3*res-1)/(c3*e3*res)
  !print*, n1, n2, n3

  ! Referring to Equations 11.75, we next obtain the step masses of each stage, 
  ! beginning with stage N and working our way down the stack to stage 1.

  mass_stage_3 = (n3 -1)/(1-n3*e3)*mass_pay_load
  mass_stage_2 = (n2 -1)/(1-n2*e2)*(mass_pay_load + mass_stage_3)
  mass_stage_1 = (n1 -1)/(1-n1*e1)*(mass_pay_load + mass_stage_3 +mass_stage_2)
  mass_0 = mass_stage_1 + mass_stage_2 + mass_stage_3 + mass_pay_load
  ! Stage 1 masses
  mass_empty_stage_1 = e1*mass_stage_1
  mass_prop_stage_1 = mass_stage_1 - mass_empty_stage_1
  ! Stage 2 masses
  mass_empty_stage_2 = e2*mass_stage_2
  mass_prop_stage_2 = mass_stage_2 - mass_empty_stage_2
  ! Stage 3 masses
  mass_empty_stage_3 = e3*mass_stage_3
  mass_prop_stage_3 = mass_stage_3 - mass_empty_stage_3

  ! A positive number in every instance means we have indeed found a local 
  ! minimum of the function in Equation 11.85.
  sum = 0
  check = res*c1*(e1*n1-1)**2 + 2*e1*n1 -1 
  if( check > 0) sum = sum +1
  check = res*c2*(e2*n2-1)**2 + 2*e2*n2 -1 
  if( check > 0) sum = sum +1
  check = res*c3*(e3*n3-1)**2 + 2*e3*n3 -1 
  if( check > 0) sum = sum +1
  if(sum==3)then
     print*, "  ### Found a local minimum ###"  
  else
     print*, "Local minimun not foud, try again"
     stop
  end if

  
  print*, " 3-stage Rocket OPTIMAL STAGING mass for given:"
  print*, " Specific impulse for each stage in [seg]"
  print*, " Isp_1", Isp1
  print*, " Isp_2", Isp2
  print*, " Isp_3", Isp3
  print*, " Structural ratio for each stage in [-]"
  print*, " e1", e1
  print*, " e2", e2
  print*, " e3", e3
  print*, "Burn off velocity: [Km/seg]:", v_burn_off
  print*, " ############# Results ###############"

  print*, "The total mass of the vehicle is [Kg]:", mass_0
  print*,"For the step masses"
  print*, "##################################"
  print*," Stage 1:"
  print*," Total mass [Kg]:", mass_stage_1 
  print*," Empty mass [Kg]:", mass_empty_stage_1
  print*," Propellant mass [Kg]", mass_prop_stage_1
  print*, "##################################"
  print*," Stage 2:"
  print*," Total mass [Kg]:", mass_stage_2 
  print*," Empty mass [Kg]:", mass_empty_stage_2
  print*," Propellant mass [Kg]", mass_prop_stage_2
  print*, "##################################"
  print*," Stage 3:"
  print*," Total mass [Kg]:", mass_stage_3 
  print*," Empty mass [Kg]:", mass_empty_stage_3
  print*," Propellant mass [Kg]", mass_prop_stage_3

100 format(A, f16.4)
end Program optimalStagedRocket

real(8) function get_optimal_mass(x)
  use dataEntry
  implicit none
  real(8) x, last_sum, c_sum
  ! equation 11.86 Orbital mechanic Howard Curtis
  ! ci sum   unit compatibility [km/s]
  !c1 = Isp1*g0/1000 ; c2 = Isp2*g0/1000 ; c3 = Isp3*g0/1000
  c_sum = c1 + c2 + c3 
  last_sum = c1*log(c1*e1) + c2*log(c2*e2) + c3*log(c3*e3)
  get_optimal_mass = c1*log(c1*x-1) + c2*log(c2*x-1) + c3*log(c3*x-1) -c_sum*log(x) - last_sum - v_burn_off

end function get_optimal_mass
