!
!     CalculiX - A 3-dimensional finite element program
!              Copyright (C) 1998-2015 Guido Dhondt
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation(version 2);
!     
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of 
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
!     GNU General Public License for more details.
!
!     You should have received a copy of the GNU General Public License
!     along with this program; if not, write to the Free Software
!     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
!
      subroutine gen3delem(kon,ipkon,lakon,ne,ipompc,nodempc,coefmpc,
     &  nmpc,nmpc_,mpcfree,ikmpc,ilmpc,labmpc,ikboun,ilboun,nboun,
     &  nboun_,nodeboun,ndirboun,xboun,iamboun,nam,
     &  inotr,trab,nk,nk_,iponoel,inoel,iponor,xnor,thicke,thickn,
     &  knor,istep,offset,t0,t1,ikforc,ilforc,rig,nforc,
     &  nforc_,nodeforc,ndirforc,xforc,iamforc,sideload,
     &  nload,ithermal,ntrans,co,ixfree,ikfree,inoelfree,iponoelmax,
     &  iperturb,tinc,tper,tmin,tmax,ctrl,typeboun,nmethod,nset,set,
     &  istartset,iendset,ialset,prop,ielprop,vold,mi,nkon,ielmat,
     &  icomposite,t0g,t1g,idefforc,iamt1,orname,orab,norien,norien_,
     &  ielorien)
!
!     generates three-dimensional elements:
!         for plane stress
!         for plane strain
!         for plate and shell elements
!         for beam elements
!
      implicit none
!
      character*1 typeboun(*)
      character*8 lakon(*)
      character*20 labmpc(*),sideload(*)
      character*80 orname(*)
      character*81 set(*)
!
      integer ipompc(*),nodempc(3,*),nmpc,nmpc_,mpcfree,ikmpc(*),
     &  ilmpc(*),kon(*),ipkon(*),ne,indexe,i,j,node,
     &  ikboun(*),ilboun(*),nboun,nboun_,
     &  neigh(7,8),nodeboun(*),ndirboun(*),nk,
     &  nk_,iponoel(*),inoel(3,*),inoelfree,istep,nmpcold,
     &  ikforc(*),ilforc(*),nodeforc(2,*),ndirforc(*),iamforc(*),
     &  nforc,nforc_,ithermal(2),nload,iamboun(*),
     &  ntrans,inotr(2,*),nam,iponoelmax,iperturb,numnod,itransaxial,
     &  rig(*),nmethod,nset,istartset(*),iendset(*),ialset(*),nkon,
     &  ielprop(*),mi(*),nope,
     &  ielmat(mi(3),*),iponor(2,*),knor(*),ixfree,ikfree,icomposite,
     &  idefforc(*),idim,iamt1(*),norien,norien_,ielorien(mi(3),*)
!
      real*8 coefmpc(*),thicke(mi(3),*),xnor(*),thickn(2,*),tinc,
     &  tper,tmin,t0g(2,*),t1g(2,*),e1(3),e2(3),xt1(3),orab(7,*),
     &  tmax,offset(2,*),t0(*),t1(*),xforc(*),trab(7,*),co(3,*),
     &  xboun(*),pi,ctrl(*),prop(*),vold(0:mi(2),*),
     &  coloc(3,8)
!
      data neigh /1,9,2,12,4,17,5,2,9,1,10,3,18,6,
     &            3,11,4,10,2,19,7,4,11,3,12,1,20,8,
     &            5,13,6,16,8,17,1,6,13,5,14,7,18,2,
     &            7,15,8,14,6,19,3,8,15,7,16,5,20,4/
!
      data coloc /-1.,-1.,-1.,1.,-1.,-1.,1.,1.,-1.,-1.,1.,-1.,
     &            -1.,-1.,1.,1.,-1.,1.,1.,1.,1.,-1.,1.,1./
!
      pi=4.d0*datan(1.d0)
!
!     catalogueing the element per node relationship for shell/beam
!     elements and transferring the nodal thickness to the elements
!
!     inoelfree=1 means that there is at least one 1D or 2D element
!     in the structure. Otherwise inoelfree=0.
!
      if((istep.eq.1).and.(inoelfree.eq.1)) then
!
!        shift of the connectivity for composite elements
!
         if(icomposite.eq.1) then
            call changekon(ne,ipkon,lakon,mi,nkon,thicke,ielmat,kon)
         endif
!
         itransaxial=0
!
         do i=1,ne
            if(ipkon(i).lt.0) cycle
            if((lakon(i)(1:2).ne.'C3').and.(lakon(i)(1:1).ne.'D').and.
     &         (lakon(i)(1:1).ne.'G').and.(lakon(i)(1:1).ne.'E')) then
!
!              number of nodes belonging to the element
!
               if((lakon(i)(1:3).eq.'B31').or.
     &            (lakon(i)(1:4).eq.'T3D2')) then
                  numnod=2
               elseif((lakon(i)(1:1).eq.'B').or.
     &                (lakon(i)(1:1).eq.'T')) then
                  numnod=3
               elseif((lakon(i)(2:2).eq.'3').or.
     &                (lakon(i)(4:4).eq.'3')) then
                  numnod=3
               elseif((lakon(i)(2:2).eq.'4').or.
     &                (lakon(i)(4:4).eq.'4')) then
                  numnod=4
               elseif((lakon(i)(2:2).eq.'6').or.
     &                (lakon(i)(4:4).eq.'6')) then
                  numnod=6
               elseif((lakon(i)(2:2).eq.'8').or.
     &                (lakon(i)(4:4).eq.'8')) then
                  numnod=8
               endif
!
               indexe=ipkon(i)
               do j=1,numnod
                  node=kon(indexe+j)
                  iponoelmax=max(iponoelmax,node)
                  inoel(1,inoelfree)=i
                  inoel(2,inoelfree)=j
                  inoel(3,inoelfree)=iponoel(node)
                  iponoel(node)=inoelfree
                  inoelfree=inoelfree+1
                  if(lakon(i)(1:2).ne.'CA') then
                     if(thickn(1,node).gt.0.d0)
     &                    thicke(1,indexe+j)=thickn(1,node)
                     if(mi(3).gt.1) then
                        if(thickn(2,node).gt.0.d0)
     &                       thicke(2,indexe+j)=thickn(2,node)
                     endif
                  endif
                  if(thicke(1,indexe+j).le.0.d0) then
                     if(lakon(i)(1:1).eq.'C') then
!
!                       default for plane stress and plane strain elements
!
                        thicke(1,indexe+j)=1.d0
                     else
                        write(*,*)'*ERROR in gen3delem: first thickness'
                        write(*,*)'       in node ',j,' of element ',i
                        write(*,*)'       is zero'
                        call exit(201)
                     endif
                  endif
                  if((lakon(i)(1:1).eq.'B').and.
     &                 (thicke(2,indexe+j).le.0.d0)) then
                     write(*,*) '*ERROR in gen3delem: second thickness'
                     write(*,*)'       in node ',j,' of beam element ',i
                     write(*,*)'       is zero'
                     call exit(201)
                  endif
               enddo
            endif
         enddo
!
!     calculating the normals in nodes belonging to shells/beams
!
         nmpcold=nmpc
!
         call gen3dnor(nk,nk_,co,iponoel,inoel,iponoelmax,kon,ipkon,
     &     lakon,ne,thicke,offset,iponor,xnor,knor,rig,iperturb,tinc,
     &     tper,tmin,tmax,ctrl,ipompc,nodempc,coefmpc,nmpc,nmpc_,
     &     mpcfree,ikmpc,ilmpc,labmpc,ikboun,ilboun,nboun,nboun_,
     &     nodeboun,ndirboun,xboun,iamboun,typeboun,nam,ntrans,inotr,
     &     trab,ikfree,ixfree,nmethod,ithermal,istep,mi,icomposite,
     &     ielmat,vold)
!
      endif
!
      if(istep.eq.1) then
!
!        if there is any plane stress, plane strain or axisymmetric
!        element the structure should lie in the z=0 plane
!
         if(inoelfree.ne.0) then
            do i=1,ne
               if(ipkon(i).lt.0) cycle
               if((lakon(i)(1:2).eq.'CP').or.
     &              (lakon(i)(1:2).eq.'CA')) then
                  indexe=ipkon(i)
                  read(lakon(i)(4:4),'(i1)') nope
c                  if(lakon(i)(4:4).eq.'6') then
c                     nope=6
c                  else
c                     nope=8
c                  endif
                  do j=1,nope
                     node=kon(indexe+j)
                     if(dabs(co(3,node)).gt.0.d0) then
                        write(*,*) '*ERROR in gen3delem. The structure'
                        write(*,*) '       contains plane stress, plane'
                        write(*,*) '       strain or axisymmetric'
                        write(*,*) '       elements and should lie in '
                        write(*,*) '       the z=0 plane. This is at'
                        write(*,*) '       least not the case for node',
     &                       node
                        call exit(201)
                     endif
                  enddo
               endif
            enddo
         endif
!
!        1D and 2D elements
!
         if(inoelfree.ne.0) then
            do i=1,ne
               if(ipkon(i).lt.0) cycle
               if((lakon(i)(1:2).eq.'CP').or.
     &              (lakon(i)(1:1).eq.'S').or.
     &              (lakon(i)(1:1).eq.'M').or.
     &              (lakon(i)(1:2).eq.'CA')) then
!
                 call gen3dfrom2d(i,kon,ipkon,lakon,ne,iponor,xnor,knor,
     &           thicke,offset,ntrans,inotr,trab,ikboun,ilboun,nboun,
     &           nboun_,nodeboun,ndirboun,xboun,iamboun,typeboun,ipompc,
     &           nodempc,coefmpc,nmpc,nmpc_,mpcfree,ikmpc,ilmpc,labmpc,
     &           nk,nk_,co,rig,nmethod,iperturb,ithermal,mi,nam,
     &           icomposite,ielmat,vold,orname,orab,norien,norien_,
     &           ielorien)
!            
              elseif((lakon(i)(1:1).eq.'B').or.
     &               (lakon(i)(1:1).eq.'T')) then
                 call gen3dfrom1d(i,kon,ipkon,lakon,ne,iponor,xnor,knor,
     &                thicke,ntrans,inotr,trab,nk,nk_,co,offset,mi)
              endif
!     
              if(lakon(i)(1:4).eq.'CPE3') then
                 lakon(i)(1:7)='C3D6  E'
              elseif(lakon(i)(1:5).eq.'CPE4R') then
                 lakon(i)(1:7)='C3D8R E'
              elseif(lakon(i)(1:4).eq.'CPE4') then
                 lakon(i)(1:7)='C3D8  E'
              elseif(lakon(i)(1:4).eq.'CPE6') then
                 lakon(i)(1:7)='C3D15 E'
              elseif(lakon(i)(1:5).eq.'CPE8R') then
                 lakon(i)(1:7)='C3D20RE'
              elseif(lakon(i)(1:4).eq.'CPE8') then
                 lakon(i)(1:7)='C3D20 E'
              elseif(lakon(i)(1:4).eq.'CPS3') then
                 lakon(i)(1:7)='C3D6  S'
              elseif(lakon(i)(1:5).eq.'CPS4R') then
                 lakon(i)(1:7)='C3D8R S'
              elseif(lakon(i)(1:4).eq.'CPS4') then
                 lakon(i)(1:7)='C3D8  S'
              elseif(lakon(i)(1:4).eq.'CPS6') then
                 lakon(i)(1:7)='C3D15 S'
              elseif(lakon(i)(1:5).eq.'CPS8R') then
                 lakon(i)(1:7)='C3D20RS'
              elseif(lakon(i)(1:4).eq.'CPS8') then
                 lakon(i)(1:7)='C3D20 S'
              elseif(lakon(i)(1:4).eq.'CAX3') then
                 lakon(i)(1:7)='C3D6  A'
              elseif(lakon(i)(1:5).eq.'CAX4R') then
                 lakon(i)(1:7)='C3D8R A'
              elseif(lakon(i)(1:4).eq.'CAX4') then
                 lakon(i)(1:7)='C3D8  A'
              elseif(lakon(i)(1:4).eq.'CAX6') then
                 lakon(i)(1:7)='C3D15 A'
              elseif(lakon(i)(1:5).eq.'CAX8R') then
                 lakon(i)(1:7)='C3D20RA'
              elseif(lakon(i)(1:4).eq.'CAX8') then
                 lakon(i)(1:7)='C3D20 A'
              elseif((lakon(i)(1:2).eq.'S3').or.
     &               (lakon(i)(1:4).eq.'M3D3')) then
                 lakon(i)(1:7)='C3D6  L'
              elseif((lakon(i)(1:3).eq.'S4R').or.
     &               (lakon(i)(1:5).eq.'M3D4R')) then
                 lakon(i)(1:7)='C3D8R L'
              elseif((lakon(i)(1:2).eq.'S4').or.
     &               (lakon(i)(1:4).eq.'M3D4')) then
                 lakon(i)(1:7)='C3D8I L'
              elseif((lakon(i)(1:2).eq.'S6').or.
     &               (lakon(i)(1:4).eq.'M3D6')) then
                 lakon(i)(1:7)='C3D15 L'
              elseif((lakon(i)(1:3).eq.'S8R').or.
     &               (lakon(i)(1:5).eq.'M3D8R')) then
                 lakon(i)(1:7)='C3D20RL'
              elseif((lakon(i)(1:2).eq.'S8').or.
     &               (lakon(i)(1:4).eq.'M3D8')) then
                 lakon(i)(1:7)='C3D20 L'
              elseif(lakon(i)(1:4).eq.'B31R') then
                 lakon(i)(1:7)='C3D8R B'
              elseif((lakon(i)(1:3).eq.'B31').or.
     &               (lakon(i)(1:4).eq.'T3D2')) then
                 lakon(i)(1:7)='C3D8I B'
              elseif(lakon(i)(1:4).eq.'B32R') then
                 lakon(i)(1:7)='C3D20RB'
              elseif((lakon(i)(1:3).eq.'B32').or.
     &               (lakon(i)(1:4).eq.'T3D3')) then
                 lakon(i)(1:7)='C3D20 B'
              endif
           enddo
c     Bernhardi start
        endif
        do i=1,ne
           if(lakon(i)(1:5).eq.'C3D8I') then
              call genmodes(i,kon,ipkon,lakon,ne,nk,nk_,co)
           endif
        enddo
c     Bernhardi end
!
!        filling the new KNOT MPC's (needs the coordinates
!        of the expanded nodes)
!
         if(inoelfree.ne.0) then
            call fillknotmpc(co,ipompc,nodempc,coefmpc,labmpc,
     &           nmpc,nmpcold,mpcfree,idim,e1,e2,xt1)
c            call gen3dprop(prop,ielprop,iponoel,inoel,iponoelmax,kon,
c     &           ipkon,lakon,ne,iponor,xnor,knor,ipompc,nodempc,coefmpc,
c     &           nmpc,nmpc_,mpcfree,ikmpc,ilmpc,labmpc,rig,ntrans,inotr,
c     &           trab,nam,nk,nk_,co,nmethod,iperturb)
         endif
!     
      endif
!
!        generating MPC's to connect shells and beams with solid
!        elements
!
      if((inoelfree.ne.0).and.(istep.eq.1)) then
         call gen3dconnect(kon,ipkon,lakon,ne,iponoel,inoel,
     &     iponoelmax,rig,iponor,xnor,knor,ipompc,nodempc,coefmpc,nmpc,
     &     nmpc_,mpcfree,ikmpc,ilmpc,labmpc)
      endif
!
      if(inoelfree.ne.0) then
!
!           multiplying existing boundary conditions
!
         call gen3dboun(ikboun,ilboun,nboun,nboun_,nodeboun,ndirboun,
     &     xboun,iamboun,typeboun,iponoel,inoel,iponoelmax,kon,ipkon,
     &     lakon,ne,iponor,xnor,knor,ipompc,nodempc,coefmpc,nmpc,nmpc_,
     &     mpcfree,ikmpc,ilmpc,labmpc,rig,ntrans,inotr,trab,nam,nk,nk_,
     &     co,nmethod,iperturb,istep,vold,mi)
!
!        updating the nodal surfaces: establishing links between the user
!        defined nodes and the newly generated nodes (mid-nodes
!        for 2d elements, mean of corner nodes for 1d elements)
!
         if(istep.eq.1) then
            call gen3dsurf(iponoel,inoel,iponoelmax,kon,ipkon,
     &        lakon,ne,iponor,knor,ipompc,nodempc,coefmpc,nmpc,nmpc_,
     &        mpcfree,ikmpc,ilmpc,labmpc,rig,ntrans,inotr,trab,nam,nk,
     &        nk_,co,nmethod,iperturb,nset,set,istartset,iendset,ialset,
     &        ikboun,ilboun,nboun,nboun_,nodeboun,ndirboun,xboun,
     &        iamboun,typeboun,mi,vold)
         endif
!
!        updating the MPCs: establishing links between the user
!        defined nodes and the newly generated nodes (mid-nodes
!        for 2d elements, mean of corner nodes for 1d elements)
!
!        is needed in each step since new SPC's in local 
!        coordinates can be defined which correspond to
!        MPC's in global coordinates
!
c         if(istep.eq.1) then
            call gen3dmpc(ipompc,nodempc,coefmpc,nmpc,nmpc_,mpcfree,
     &        ikmpc,ilmpc,labmpc,iponoel,inoel,iponoelmax,kon,ipkon,
     &        lakon,ne,iponor,xnor,knor,rig)
c         endif
!
!        updating the temperatures
!
         if(ithermal(1).gt.0) then
            call gen3dtemp(iponoel,inoel,iponoelmax,kon,ipkon,lakon,ne,
     &           iponor,xnor,knor,t0,t1,thicke,offset,rig,nk,nk_,co,
     &           istep,ithermal,vold,mi,t0g,t1g,nam,iamt1)
         endif
!
!        updating the concentrated loading
!
         call gen3dforc(ikforc,ilforc,nforc,nforc_,nodeforc,
     &     ndirforc,xforc,iamforc,ntrans,inotr,trab,rig,ipompc,nodempc,
     &     coefmpc,nmpc,nmpc_,mpcfree,ikmpc,ilmpc,labmpc,iponoel,inoel,
     &     iponoelmax,kon,ipkon,lakon,ne,iponor,xnor,knor,nam,nk,nk_,
     &     co,thicke,nodeboun,ndirboun,ikboun,ilboun,nboun,nboun_,
     &     iamboun,typeboun,xboun,nmethod,iperturb,istep,vold,mi,
     &     idefforc)
      endif
!
      return
      end


