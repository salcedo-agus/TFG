Module dataEntry
  implicit none
  integer, parameter :: n_stage = 3
  ! Isp in seconds [s]
  real(8), parameter :: Isp1 = 400.
  real(8), parameter :: Isp2 = 350.
  real(8), parameter :: Isp3 = 300.
  ! structural parameter [-]
  real(8), parameter :: e1 = 0.10
  real(8), parameter :: e2 = 0.15
  real(8), parameter :: e3 = 0.20
  ! Pay load mass in [Kg]
  real(8), parameter :: mass_pay_load = 5000.
  ! Burn off velocity [km/s]
  real(8), parameter :: v_burn_off = 10.

  ! Acceleration due to gravity at surface [m s^-2]
  real(8), parameter :: g0 = 9.81
  real(8) c1, c2, c3

contains
  subroutine init_data()
    implicit none
    ! ci sum   unit compatibility [km/s]
    c1 = Isp1*g0/1000 ; c2 = Isp2*g0/1000 ; c3 = Isp3*g0/1000
  end subroutine init_data
end Module dataEntry
