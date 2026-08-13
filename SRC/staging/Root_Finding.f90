module Root_Finding_Methods
    implicit none
    abstract interface
        function func_interface(x, Rocket)
            use rocket_types
            implicit none
            real(8), intent(in) :: x
            type(Rocket_t), intent(in) :: Rocket
            real(8) func_interface 
        end function func_interface
    end interface
contains

function Bolzano_Interval_Start(f, Rocket)
    !This function finds the first finite value of L (not NAN or inf) to use in 
    !the Bolzano root finding method 
    USE, INTRINSIC :: IEEE_ARITHMETIC
    use rocket_types
    implicit none
    procedure(func_interface), pointer, intent(in) :: f
    type(Rocket_t), intent(in) :: Rocket 
    real(8) Bolzano_Interval_Start
    real(8) Left_Bracket    
    integer i

    Left_Bracket = 0.d0 !First aproximation 
    i = 0.d0
    do while (.not. ieee_is_finite(f(Left_Bracket, Rocket)) .and. i<500)
        Left_Bracket = Left_Bracket + 0.01d0
        i = i + 1
    end do 

    if (.not. ieee_is_finite(f(Left_Bracket, Rocket))) print*, "Valid start point not found"
    print*, "Bolzano Interval Start =", Left_Bracket 
    Bolzano_Interval_Start = Left_Bracket 
end function 

subroutine Bolzano_Bisection(f, Rocket, Left_Bracket, Right_Bracket, tol, root, iterations)
    use rocket_types
    procedure(func_interface), pointer, intent(in) :: f
    type(Rocket_t), intent(in)  :: Rocket
    real(8), intent(in)  :: Left_Bracket, Right_Bracket
    real(8), intent(in)  :: tol
    integer, intent(out) :: iterations
    real(8), intent(out) :: root 
    real(8) res 
    real(8) fa, fb, fc                  ! Values of the function at a, b and c 
    real(8) a, b, c
    integer i

    a = Left_Bracket 
    b = Right_Bracket
    c = 0.d0

    ! Bolzano's bisection method 
    i = 0
    res = 1905.d0
    do while (res > tol .and. i < 100)               
        c = (a+b)/2.d0
        fa = f(a, Rocket)
        fb = f(b, Rocket)
        fc = f(c, Rocket)
        print*, c
        if (fa*fc < 0) then 
            b = c
        else if (fb*fc < 0) then
            a = c
        else 
            print*, "Raiz fuera del rango"
        end if 
       ! res = abs(a - b)
        res = abs(f(c, Rocket))     
        i = i + 1
    end do 
    print*, "====================================="
    print*, "iter:  ", i
    print*, "a=     ", a
    print*, "g(a)=  ", f(a, Rocket)
    print*, "b=     ", b
    print*, "g(b)=  ", f(b, Rocket)
    print*, "res=   ", res
    print*, "====================================="

    root = c 
    iterations = i 
  end subroutine Bolzano_Bisection

  subroutine Newton_Raphson(f, Rocket) !NOT WORKING
    use rocket_types
    procedure(func_interface), pointer, intent(in) :: f
    type(Rocket_t) Rocket


    !Newton-Raphson method
    !do while (res > 1.e-3 .and. i < 100)
    !    Ln = L
    !    L  = L - g(L, Rocket)*2*h/(g(L+h, Rocket) - g(L-h, Rocket)) 
    !    i = i + 1
    !    res = abs(L - Ln)
    !    print*, "====================================="
    !    print*, "iter:  ", i
    !    print*, "Ln=    ", Ln 
    !    print*, "g(L)=  ", g(Ln, Rocket)
    !    print*, "g(L+h)=", g(Ln+h, Rocket) 
    !    print*, "g(L-h)=", g(Ln-h, Rocket)
    !    print*, "L=     ", L
    !    print*, "res=   ", res
    !    print*, "====================================="
    !end do
  end subroutine Newton_Raphson
end module Root_Finding_Methods