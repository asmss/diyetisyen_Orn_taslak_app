import { useEffect, useMemo, useState } from 'react';
import {
  addDoc,
  collection,
  doc,
  getDoc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { deleteDoc } from 'firebase/firestore';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { firebaseAuth, firestore } from './firebase';

const initialAppointmentForm = {
  userId: '',
  title: 'Haftalik kontrol',
  dateTime: '',
  durationMinutes: '30',
  notes: '',
};

const initialDietForm = {
  userId: '',
  title: 'Yeni diyet plani',
  startDate: '',
  endDate: '',
  waterTargetLiters: '2.2',
  notes: '',
  breakfast: '',
  lunch: '',
  snack: '',
  dinner: '',
};

function App() {
  const [authUser, setAuthUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isCheckingAdmin, setIsCheckingAdmin] = useState(true);
  const [loginForm, setLoginForm] = useState({ email: '', password: '' });
  const [users, setUsers] = useState([]);
  const [appointments, setAppointments] = useState([]);
  const [dietPlans, setDietPlans] = useState([]);
  const [appointmentForm, setAppointmentForm] = useState(initialAppointmentForm);
  const [dietForm, setDietForm] = useState(initialDietForm);
  const [statusMessage, setStatusMessage] = useState('');
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(firebaseAuth, async (user) => {
      setAuthUser(user);

      if (!user) {
        setIsAdmin(false);
        setIsCheckingAdmin(false);
        return;
      }

      setIsCheckingAdmin(true);
      const adminSnapshot = await getDoc(doc(firestore, 'admins', user.uid));
      setIsAdmin(adminSnapshot.exists());
      setIsCheckingAdmin(false);
    });

    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!authUser || !isAdmin) {
      setUsers([]);
      setAppointments([]);
      setDietPlans([]);
      return undefined;
    }

    const unsubscribers = [
      onSnapshot(query(collection(firestore, 'users')), (snapshot) => {
        setUsers(
          snapshot.docs.map((entry) => ({
            id: entry.id,
            ...entry.data(),
          })),
        );
      }),
      onSnapshot(
        query(collection(firestore, 'appointments'), orderBy('dateTime')),
        (snapshot) => {
          setAppointments(
            snapshot.docs.map((entry) => ({
              id: entry.id,
              ...entry.data(),
            })),
          );
        },
      ),
      onSnapshot(
        query(collection(firestore, 'dietPlans'), orderBy('startDate', 'desc')),
        (snapshot) => {
          setDietPlans(
            snapshot.docs.map((entry) => ({
              id: entry.id,
              ...entry.data(),
            })),
          );
        },
      ),
    ];

    return () => {
      unsubscribers.forEach((unsubscribe) => unsubscribe());
    };
  }, [authUser, isAdmin]);

  useEffect(() => {
    if (!appointmentForm.userId && users[0]?.id) {
      setAppointmentForm((prev) => ({ ...prev, userId: users[0].id }));
    }

    if (!dietForm.userId && users[0]?.id) {
      setDietForm((prev) => ({ ...prev, userId: users[0].id }));
    }
  }, [users, appointmentForm.userId, dietForm.userId]);

  const metrics = useMemo(
    () => [
      {
        label: 'Aktif müşteriler',
        value: String(users.length).padStart(2, '0'),
        icon: '',
        color: 'blue',
      },
      {
        label: 'Randevular',
        value: String(appointments.length).padStart(2, '0'),
        icon: '',
        color: 'green',
      },
      {
        label: 'Diyet planları',
        value: String(dietPlans.length).padStart(2, '0'),
        icon: '',
        color: 'purple',
      },
    ],
    [appointments.length, dietPlans.length, users.length],
  );

  const usersById = useMemo(
    () =>
      Object.fromEntries(
        users.map((user) => [
          user.id,
          { fullName: user.fullName || 'İsimsiz kullanıcı', ...user },
        ]),
      ),
    [users],
  );

  async function handleLogin(event) {
    event.preventDefault();

    try {
      setStatusMessage('');
      await signInWithEmailAndPassword(
        firebaseAuth,
        loginForm.email.trim(),
        loginForm.password,
      );
    } catch (error) {
      setStatusMessage(`Admin girişi başarısız: ${error.message}`);
    }
  }

  async function handleLogout() {
    await signOut(firebaseAuth);
    setStatusMessage('');
  }

  async function submitAppointment(event) {
    event.preventDefault();
    const selectedUser = usersById[appointmentForm.userId];
    if (!selectedUser || !appointmentForm.dateTime) {
      setStatusMessage('Randevu oluşturmak için kullanıcı ve tarih seç.');
      return;
    }

    await addDoc(collection(firestore, 'appointments'), {
      userId: selectedUser.id,
      userName: selectedUser.fullName,
      title: appointmentForm.title,
      dateTime: new Date(appointmentForm.dateTime),
      durationMinutes: Number(appointmentForm.durationMinutes),
      notes: appointmentForm.notes,
      status: 'upcoming',
      createdAt: serverTimestamp(),
    });

    setAppointmentForm({
      ...initialAppointmentForm,
      userId: selectedUser.id,
    });
    setStatusMessage('✓ Yeni randevu kaydı oluşturuldu.');
  }

  async function deleteAppointment(appointmentId) {
    const confirmDelete = window.confirm("Bu randevuyu tamamen silmek istediğinize emin misiniz?");

    if (confirmDelete) {
      try {
        const appointmentRef = doc(firestore, 'appointments', appointmentId);
        await deleteDoc(appointmentRef);
        setStatusMessage('✓ Randevu başarıyla silindi.');
      } catch (error) {
        setStatusMessage(`✗ Silme hatası: ${error.message}`);
      }
    }
  }

  async function updateAppointmentStatus(appointmentId, newStatus) {
    try {
      const appointmentRef = doc(firestore, 'appointments', appointmentId);
      await updateDoc(appointmentRef, { status: newStatus });
      const statusText = newStatus === 'upcoming' ? 'Onaylandı' : 'İptal edildi';
      setStatusMessage(`✓ Randevu durumu '${statusText}' olarak güncellendi.`);
    } catch (error) {
      setStatusMessage(`✗ Hata: ${error.message}`);
    }
  }

  async function submitDietPlan(event) {
    event.preventDefault();
    const selectedUser = usersById[dietForm.userId];
    if (!selectedUser || !dietForm.startDate || !dietForm.endDate) {
      setStatusMessage('Diyet planı için kullanıcı ve tarih aralığı seç.');
      return;
    }

    await addDoc(collection(firestore, 'dietPlans'), {
      userId: selectedUser.id,
      userName: selectedUser.fullName,
      title: dietForm.title,
      dietitianName: 'Uzm. Dyt. Melis Kaya',
      startDate: new Date(dietForm.startDate),
      endDate: new Date(dietForm.endDate),
      waterTargetLiters: Number(dietForm.waterTargetLiters),
      notes: dietForm.notes,
      meals: [
        {
          timeLabel: '08:00',
          title: 'Kahvaltı',
          description: dietForm.breakfast || 'Kahvaltı bilgisi eklenmedi.',
        },
        {
          timeLabel: '12:30',
          title: 'Öğle',
          description: dietForm.lunch || 'Öğle öğünü bilgisi eklenmedi.',
        },
        {
          timeLabel: '16:00',
          title: 'Ara öğün',
          description: dietForm.snack || 'Ara öğün bilgisi eklenmedi.',
        },
        {
          timeLabel: '19:00',
          title: 'Akşam',
          description: dietForm.dinner || 'Akşam öğünü bilgisi eklenmedi.',
        },
      ],
      createdAt: serverTimestamp(),
    });

    setDietForm({
      ...initialDietForm,
      userId: selectedUser.id,
    });
    setStatusMessage('✓ Diyet planı başarıyla yazıldı.');
  }

  const pendingAppointments = appointments.filter(a => a.status === 'pending');
  const otherAppointments = appointments.filter(a => a.status !== 'pending');

  if (!authUser) {
    return (
      <div style={styles.authContainer}>
        <style>{`
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        `}</style>
        <form style={styles.authCard} onSubmit={handleLogin}>
          <div style={styles.authHeader}>
            <div style={styles.authLogo}>💉</div>
            <h1 style={styles.authTitle}>Diyetisyen Paneli</h1>
            <p style={styles.authSubtitle}>Admin erişimi</p>
          </div>
          
          <div style={styles.authFormGroup}>
            <label style={styles.label}>E-posta</label>
            <input
              type="email"
              placeholder="admin@example.com"
              value={loginForm.email}
              onChange={(event) =>
                setLoginForm((prev) => ({ ...prev, email: event.target.value }))
              }
              style={styles.authInput}
            />
          </div>

          <div style={styles.authFormGroup}>
            <label style={styles.label}>Şifre</label>
            <input
              type="password"
              placeholder="••••••••"
              value={loginForm.password}
              onChange={(event) =>
                setLoginForm((prev) => ({ ...prev, password: event.target.value }))
              }
              style={styles.authInput}
            />
          </div>

          <button type="submit" style={styles.authButton}>
            Giriş yap
          </button>

          {statusMessage && (
            <div style={styles.statusMessage}>{statusMessage}</div>
          )}


        </form>
      </div>
    );
  }

  if (isCheckingAdmin) {
    return (
      <div style={styles.authContainer}>
        <div style={styles.authCard}>
          <div style={styles.loadingSpinner}></div>
          <p style={styles.loadingText}>Admin doğrulanıyor...</p>
        </div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div style={styles.authContainer}>
        <div style={styles.authCard}>
          <p style={styles.errorIcon}>⛔</p>
          <h1 style={{ ...styles.authTitle, color: '#dc2626' }}>Yetkisiz erişim</h1>
          <p style={styles.authHint}>Bu hesap admin değildir.</p>
          <button type="button" onClick={handleLogout} style={styles.authButton}>
            Çıkış yap
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.pageContainer}>
      <aside style={styles.sidebar}>
        <div style={styles.sidebarHeader}>
          <div style={styles.logo}>💉</div>
          <h1 style={styles.sidebarTitle}>Diyetisyen Kontrol Merkezi</h1>
          <p style={styles.userEmail}>{authUser.email}</p>
        </div>

        <nav style={styles.nav}>
          {[
            { id: 'overview', label: '📊 Genel Bakış', icon: '📊' },
            { id: 'customers', label: '👥 Müşteriler', icon: '👥' },
            { id: 'appointments', label: '📅 Randevular', icon: '📅' },
            { id: 'plans', label: '🥗 Diyet Planları', icon: '🥗' },
            { id: 'forms', label: '📝 Form', icon: '📝' },
          ].map(tab => (
            <button
              key={tab.id}
              style={{
                ...styles.navItem,
                ...(activeTab === tab.id ? styles.navItemActive : {})
              }}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </nav>

        <button type="button" onClick={handleLogout} style={styles.logoutBtn}>
          Çıkış yap
        </button>
      </aside>

      <main style={styles.mainContent}>
        {activeTab === 'overview' && (
          <section style={styles.section}>
            <div style={styles.sectionHeader}>
              <div>
                <p style={styles.sectionEyebrow}>Admin Paneli</p>
                <h2 style={styles.sectionTitle}>Hoş geldin, {authUser.email.split('@')[0]}!</h2>
                <p style={styles.sectionDesc}>
                  Mobil uygulama kullanıcılarının randevularını ve diyet planlarını yönet.
                </p>
              </div>
              {statusMessage && (
                <div style={styles.floatingStatus}>
                  <p>{statusMessage}</p>
                  <button
                    onClick={() => setStatusMessage('')}
                    style={styles.closeStatus}
                  >×</button>
                </div>
              )}
            </div>

            <div style={styles.metricsGrid}>
              {metrics.map((metric) => (
                <div key={metric.label} style={styles.metricCard}>
                  <div style={styles.metricIcon}>{metric.icon}</div>
                  <div style={styles.metricContent}>
                    <p style={styles.metricLabel}>{metric.label}</p>
                    <strong style={styles.metricValue}>{metric.value}</strong>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {activeTab === 'customers' && (
          <section style={styles.section}>
            <div style={styles.panelHeader}>
              <h3 style={styles.panelTitle}>Aktif Müşteriler</h3>
              <span style={styles.badge}>{users.length} kişi</span>
            </div>
            {users.length === 0 ? (
              <p style={styles.emptyState}>Henüz kullanıcı yok.</p>
            ) : (
              <div style={styles.customersList}>
                {users.map((customer) => (
                  <div key={customer.id} style={styles.customerCard}>
                    <div style={styles.customerAvatar}>
                      {customer.fullName.charAt(0).toUpperCase()}
                    </div>
                    <div style={styles.customerInfo}>
                      <strong style={styles.customerName}>{customer.fullName}</strong>
                      <p style={styles.customerGoal}>{customer.goal || 'Hedef belirtilmemiş'}</p>
                    </div>
                    <div style={styles.customerWeight}>{customer.weightKg || '-'} kg</div>
                  </div>
                ))}
              </div>
            )}
          </section>
        )}

        {activeTab === 'appointments' && (
          <section style={styles.section}>
            <div style={styles.panelHeader}>
              <h3 style={styles.panelTitle}>Randevular</h3>
              <span style={styles.badge}>{appointments.length} kayıt</span>
            </div>

            {pendingAppointments.length > 0 && (
              <div style={styles.appointmentSection}>
                <h4 style={styles.sectionSubtitle}>⏳ Onay Bekleyenler</h4>
                <div style={styles.appointmentsList}>
                  {pendingAppointments.map((appointment) => (
                    <div key={appointment.id} style={styles.appointmentCardPending}>
                      <div style={styles.appointmentContent}>
                        <strong style={styles.appointmentName}>
                          {appointment.userName || usersById[appointment.userId]?.fullName}
                        </strong>
                        <p style={styles.appointmentTitle}>{appointment.title}</p>
                        <span style={styles.appointmentTime}>{formatDate(appointment.dateTime)}</span>
                      </div>
                      <div style={styles.appointmentActions}>
                        <button
                          onClick={() => updateAppointmentStatus(appointment.id, 'upcoming')}
                          style={styles.btnApprove}
                        >
                          ✓ Onayla
                        </button>
                        <button
                          onClick={() => deleteAppointment(appointment.id)}
                          style={styles.btnDelete}
                        >
                          🗑️ Sil
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div style={styles.appointmentSection}>
              <h4 style={styles.sectionSubtitle}>✓ Tüm Randevular</h4>
              {otherAppointments.length === 0 && pendingAppointments.length === 0 ? (
                <p style={styles.emptyState}>Henüz randevu oluşturulmadı.</p>
              ) : (
                <div style={styles.appointmentsList}>
                  {otherAppointments.map((appointment) => (
                    <div
                      key={appointment.id}
                      style={{
                        ...styles.appointmentCard,
                        ...(appointment.status === 'cancelled' ? styles.appointmentCardCancelled : {})
                      }}
                    >
                      <div style={styles.appointmentContent}>
                        <strong style={styles.appointmentName}>
                          {appointment.userName || usersById[appointment.userId]?.fullName}
                        </strong>
                        <p style={styles.appointmentTitle}>{appointment.title}</p>
                        <span style={{
                          ...styles.statusBadge,
                          ...(appointment.status === 'upcoming' ? styles.statusUpcoming : styles.statusCancelled)
                        }}>
                          {appointment.status === 'upcoming' ? '✓ Onaylandı' : '✗ İptal edildi'}
                        </span>
                      </div>
                      <div style={styles.appointmentRight}>
                        <span style={styles.appointmentDate}>{formatDate(appointment.dateTime)}</span>
                        {appointment.status === 'upcoming' && (
                          <button
                            onClick={() => updateAppointmentStatus(appointment.id, 'cancelled')}
                            style={styles.btnCancel}
                          >
                            İptal Et
                          </button>
                        )}
                        {appointment.status === 'cancelled' && (
                          <button
                            onClick={() => deleteAppointment(appointment.id)}
                            style={styles.btnDelete}
                          >
                            Sil
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        )}

        {activeTab === 'plans' && (
          <section style={styles.section}>
            <div style={styles.panelHeader}>
              <h3 style={styles.panelTitle}>Yazılan Diyet Planları</h3>
              <span style={styles.badge}>{dietPlans.length} plan</span>
            </div>
            {dietPlans.length === 0 ? (
              <p style={styles.emptyState}>Henüz diyet planı yazılmadı.</p>
            ) : (
              <div style={styles.plansList}>
                {dietPlans.map((plan) => (
                  <div key={plan.id} style={styles.planCard}>
                    <div style={styles.planHeader}>
                      <strong style={styles.planName}>
                        {plan.userName || usersById[plan.userId]?.fullName}
                      </strong>
                      <span style={styles.planDates}>
                        {formatDate(plan.startDate)} - {formatDate(plan.endDate)}
                      </span>
                    </div>
                    <p style={styles.planTitle}>{plan.title}</p>
                    <div style={styles.planMeta}>
                      <span>💧 {plan.waterTargetLiters}L</span>
                      <span>🍽️ {plan.meals?.length || 4} öğün</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        )}

        {activeTab === 'forms' && (
          <section style={styles.section}>
            <div style={styles.formsGrid}>
              <div style={styles.formPanel}>
                <div style={styles.formHeader}>
                  <h3 style={styles.panelTitle}>Yeni Randevu Oluştur</h3>
                </div>
                <form style={styles.form} onSubmit={submitAppointment}>
                  <div style={styles.formGroup}>
                    <label style={styles.label}>Müşteri Seç</label>
                    <select
                      value={appointmentForm.userId}
                      onChange={(event) =>
                        setAppointmentForm((prev) => ({
                          ...prev,
                          userId: event.target.value,
                        }))
                      }
                      style={styles.select}
                    >
                      <option value="">Müşteri seç...</option>
                      {users.map((user) => (
                        <option key={user.id} value={user.id}>
                          {user.fullName}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Başlık</label>
                    <input
                      type="text"
                      value={appointmentForm.title}
                      onChange={(event) =>
                        setAppointmentForm((prev) => ({
                          ...prev,
                          title: event.target.value,
                        }))
                      }
                      style={styles.input}
                      placeholder="Randevu başlığı"
                    />
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Tarih ve Saat</label>
                    <input
                      type="datetime-local"
                      value={appointmentForm.dateTime}
                      onChange={(event) =>
                        setAppointmentForm((prev) => ({
                          ...prev,
                          dateTime: event.target.value,
                        }))
                      }
                      style={styles.input}
                    />
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Süre (dakika)</label>
                    <input
                      type="number"
                      min="15"
                      step="5"
                      value={appointmentForm.durationMinutes}
                      onChange={(event) =>
                        setAppointmentForm((prev) => ({
                          ...prev,
                          durationMinutes: event.target.value,
                        }))
                      }
                      style={styles.input}
                    />
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Notlar</label>
                    <textarea
                      value={appointmentForm.notes}
                      onChange={(event) =>
                        setAppointmentForm((prev) => ({
                          ...prev,
                          notes: event.target.value,
                        }))
                      }
                      style={styles.textarea}
                      placeholder="Randevu notları..."
                      rows="3"
                    />
                  </div>

                  <button type="submit" style={styles.submitButton}>
                     Randevu Kaydet
                  </button>
                </form>
              </div>

              <div style={styles.formPanel}>
                <div style={styles.formHeader}>
                  <h3 style={styles.panelTitle}>Diyet Planı Yaz</h3>
                </div>
                <form style={styles.form} onSubmit={submitDietPlan}>
                  <div style={styles.formGroup}>
                    <label style={styles.label}>Müşteri Seç</label>
                    <select
                      value={dietForm.userId}
                      onChange={(event) =>
                        setDietForm((prev) => ({
                          ...prev,
                          userId: event.target.value,
                        }))
                      }
                      style={styles.select}
                    >
                      <option value="">Müşteri seç...</option>
                      {users.map((user) => (
                        <option key={user.id} value={user.id}>
                          {user.fullName}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Plan Başlığı</label>
                    <input
                      type="text"
                      value={dietForm.title}
                      onChange={(event) =>
                        setDietForm((prev) => ({
                          ...prev,
                          title: event.target.value,
                        }))
                      }
                      style={styles.input}
                      placeholder="Plan başlığı"
                    />
                  </div>

                  <div style={styles.twoColumn}>
                    <div style={styles.formGroup}>
                      <label style={styles.label}>Başlangıç Tarihi</label>
                      <input
                        type="date"
                        value={dietForm.startDate}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            startDate: event.target.value,
                          }))
                        }
                        style={styles.input}
                      />
                    </div>
                    <div style={styles.formGroup}>
                      <label style={styles.label}>Bitiş Tarihi</label>
                      <input
                        type="date"
                        value={dietForm.endDate}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            endDate: event.target.value,
                          }))
                        }
                        style={styles.input}
                      />
                    </div>
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Su Hedefi (Litre)</label>
                    <input
                      type="number"
                      step="0.1"
                      value={dietForm.waterTargetLiters}
                      onChange={(event) =>
                        setDietForm((prev) => ({
                          ...prev,
                          waterTargetLiters: event.target.value,
                        }))
                      }
                      style={styles.input}
                    />
                  </div>

                  <div style={styles.formGroup}>
                    <label style={styles.label}>Plan Notları</label>
                    <textarea
                      value={dietForm.notes}
                      onChange={(event) =>
                        setDietForm((prev) => ({
                          ...prev,
                          notes: event.target.value,
                        }))
                      }
                      style={styles.textarea}
                      placeholder="Genel notlar..."
                      rows="2"
                    />
                  </div>

                  <div style={styles.mealsGroup}>
                    <label style={styles.label}> Öğün Planlaması</label>
                    
                    <div style={styles.formGroup}>
                      <label style={styles.mealLabel}>Kahvaltı (08:00)</label>
                      <textarea
                        value={dietForm.breakfast}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            breakfast: event.target.value,
                          }))
                        }
                        style={styles.textarea}
                        placeholder="Kahvaltı içeriği..."
                        rows="2"
                      />
                    </div>

                    <div style={styles.formGroup}>
                      <label style={styles.mealLabel}>Öğle Öğünü (12:30)</label>
                      <textarea
                        value={dietForm.lunch}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            lunch: event.target.value,
                          }))
                        }
                        style={styles.textarea}
                        placeholder="Öğle öğünü içeriği..."
                        rows="2"
                      />
                    </div>

                    <div style={styles.formGroup}>
                      <label style={styles.mealLabel}>Ara Öğün (16:00)</label>
                      <textarea
                        value={dietForm.snack}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            snack: event.target.value,
                          }))
                        }
                        style={styles.textarea}
                        placeholder="Ara öğün içeriği..."
                        rows="2"
                      />
                    </div>

                    <div style={styles.formGroup}>
                      <label style={styles.mealLabel}>Akşam Öğünü (19:00)</label>
                      <textarea
                        value={dietForm.dinner}
                        onChange={(event) =>
                          setDietForm((prev) => ({
                            ...prev,
                            dinner: event.target.value,
                          }))
                        }
                        style={styles.textarea}
                        placeholder="Akşam öğünü içeriği..."
                        rows="2"
                      />
                    </div>
                  </div>

                  <button type="submit" style={styles.submitButton}>
                     Planı Kaydet
                  </button>
                </form>
              </div>
            </div>
          </section>
        )}
      </main>
    </div>
  );
}

function formatDate(value) {
  const date =
    value?.toDate instanceof Function ? value.toDate() : new Date(value);

  if (Number.isNaN(date.getTime())) {
    return '-';
  }

  return new Intl.DateTimeFormat('tr-TR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

const styles = {
  pageContainer: {
    display: 'flex',
    height: '100vh',
    backgroundColor: '#f8f9fa',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
  },
  authContainer: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    padding: '20px',
  },
  authCard: {
    backgroundColor: 'white',
    borderRadius: '16px',
    padding: '48px',
    width: '100%',
    maxWidth: '420px',
    boxShadow: '0 20px 60px rgba(0, 0, 0, 0.15)',
  },
  authHeader: {
    textAlign: 'center',
    marginBottom: '32px',
  },
  authLogo: {
    fontSize: '48px',
    marginBottom: '16px',
  },
  authTitle: {
    fontSize: '28px',
    fontWeight: '600',
    marginBottom: '8px',
    color: '#111',
  },
  authSubtitle: {
    fontSize: '14px',
    color: '#666',
  },
  authFormGroup: {
    marginBottom: '20px',
  },
  label: {
    display: 'block',
    fontSize: '13px',
    fontWeight: '600',
    color: '#333',
    marginBottom: '8px',
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
  },
  authInput: {
    width: '100%',
    padding: '12px 14px',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    fontSize: '14px',
    transition: 'all 0.2s',
    outline: 'none',
    ':focus': {
      borderColor: '#667eea',
      boxShadow: '0 0 0 3px rgba(102, 126, 234, 0.1)',
    },
  },
  authButton: {
    width: '100%',
    padding: '12px',
    backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    marginTop: '24px',
    transition: 'transform 0.2s, box-shadow 0.2s',
    boxShadow: '0 4px 15px rgba(102, 126, 234, 0.3)',
  },
  authHint: {
    fontSize: '12px',
    color: '#999',
    textAlign: 'center',
    marginTop: '16px',
  },
  statusMessage: {
    marginTop: '20px',
    padding: '12px',
    backgroundColor: '#fef3c7',
    color: '#92400e',
    borderRadius: '8px',
    fontSize: '13px',
    textAlign: 'center',
  },
  loadingSpinner: {
    width: '40px',
    height: '40px',
    margin: '32px auto',
    border: '4px solid #f0f0f0',
    borderTop: '4px solid #667eea',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
  },
  loadingText: {
    textAlign: 'center',
    color: '#667eea',
    fontSize: '16px',
  },
  errorIcon: {
    fontSize: '48px',
    textAlign: 'center',
    marginBottom: '16px',
  },
  sidebar: {
    width: '280px',
    backgroundColor: '#1a1f3a',
    color: 'white',
    padding: '24px',
    display: 'flex',
    flexDirection: 'column',
    borderRight: '1px solid #2d3748',
    overflowY: 'auto',
  },
  sidebarHeader: {
    marginBottom: '32px',
  },
  logo: {
    fontSize: '32px',
    marginBottom: '12px',
  },
  sidebarTitle: {
    fontSize: '18px',
    fontWeight: '600',
    marginBottom: '8px',
    color: '#fff',
  },
  userEmail: {
    fontSize: '12px',
    color: '#a0aec0',
    wordBreak: 'break-all',
  },
  nav: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    flex: 1,
  },
  navItem: {
    padding: '12px 16px',
    backgroundColor: 'transparent',
    color: '#cbd5e0',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    cursor: 'pointer',
    transition: 'all 0.2s',
    textAlign: 'left',
    fontWeight: '500',
  },
  navItemActive: {
    backgroundColor: '#667eea',
    color: 'white',
  },
  logoutBtn: {
    padding: '12px 16px',
    backgroundColor: '#dc2626',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    marginTop: 'auto',
    transition: 'all 0.2s',
  },
  mainContent: {
    flex: 1,
    overflow: 'auto',
    padding: '32px',
  },
  section: {
    marginBottom: '32px',
  },
  sectionHeader: {
    marginBottom: '32px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  sectionEyebrow: {
    fontSize: '12px',
    color: '#667eea',
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: '1px',
    marginBottom: '8px',
  },
  sectionTitle: {
    fontSize: '32px',
    fontWeight: '600',
    color: '#111',
    marginBottom: '12px',
  },
  sectionDesc: {
    fontSize: '16px',
    color: '#666',
  },
  floatingStatus: {
    backgroundColor: '#ecfdf5',
    border: '1px solid #a7f3d0',
    borderRadius: '8px',
    padding: '16px',
    maxWidth: '300px',
    boxShadow: '0 4px 12px rgba(16, 185, 129, 0.15)',
  },
  closeStatus: {
    position: 'absolute',
    right: '16px',
    top: '16px',
    background: 'none',
    border: 'none',
    fontSize: '20px',
    cursor: 'pointer',
    color: '#059669',
  },
  metricsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
    gap: '20px',
    marginBottom: '32px',
  },
  metricCard: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '24px',
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.08)',
    border: '1px solid #f0f0f0',
  },
  metricIcon: {
    fontSize: '32px',
  },
  metricContent: {
    flex: 1,
  },
  metricLabel: {
    fontSize: '13px',
    color: '#666',
    fontWeight: '500',
    marginBottom: '4px',
  },
  metricValue: {
    fontSize: '28px',
    color: '#111',
  },
  panelHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '24px',
    paddingBottom: '16px',
    borderBottom: '1px solid #e5e7eb',
  },
  panelTitle: {
    fontSize: '20px',
    fontWeight: '600',
    color: '#111',
  },
  badge: {
    backgroundColor: '#667eea',
    color: 'white',
    padding: '6px 12px',
    borderRadius: '20px',
    fontSize: '12px',
    fontWeight: '600',
  },
  customersList: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
    gap: '16px',
  },
  customerCard: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '20px',
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
    border: '1px solid #f0f0f0',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.08)',
  },
  customerAvatar: {
    width: '48px',
    height: '48px',
    borderRadius: '50%',
    backgroundColor: '#667eea',
    color: 'white',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: '600',
    fontSize: '18px',
    flexShrink: 0,
  },
  customerInfo: {
    flex: 1,
  },
  customerName: {
    fontSize: '14px',
    color: '#111',
    display: 'block',
  },
  customerGoal: {
    fontSize: '13px',
    color: '#999',
    marginTop: '4px',
  },
  customerWeight: {
    fontSize: '14px',
    fontWeight: '600',
    color: '#667eea',
  },
  emptyState: {
    textAlign: 'center',
    padding: '48px 20px',
    color: '#999',
    fontSize: '14px',
  },
  appointmentSection: {
    marginBottom: '32px',
  },
  sectionSubtitle: {
    fontSize: '16px',
    fontWeight: '600',
    color: '#111',
    marginBottom: '16px',
  },
  appointmentsList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  appointmentCardPending: {
    backgroundColor: 'white',
    border: '2px solid #fbbf24',
    borderRadius: '12px',
    padding: '16px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    boxShadow: '0 2px 8px rgba(251, 191, 36, 0.1)',
  },
  appointmentCard: {
    backgroundColor: 'white',
    border: '1px solid #e5e7eb',
    borderRadius: '12px',
    padding: '16px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  appointmentCardCancelled: {
    backgroundColor: '#f9fafb',
    opacity: '0.7',
  },
  appointmentContent: {
    flex: 1,
  },
  appointmentName: {
    fontSize: '14px',
    color: '#111',
    display: 'block',
  },
  appointmentTitle: {
    fontSize: '13px',
    color: '#666',
    marginTop: '4px',
  },
  appointmentTime: {
    fontSize: '12px',
    color: '#999',
    marginTop: '4px',
    display: 'block',
  },
  appointmentActions: {
    display: 'flex',
    gap: '8px',
  },
  btnApprove: {
    padding: '8px 12px',
    backgroundColor: '#10b981',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.2s',
  },
  btnDelete: {
    padding: '8px 12px',
    backgroundColor: '#ef4444',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.2s',
  },
  btnCancel: {
    padding: '8px 12px',
    backgroundColor: '#f97316',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.2s',
  },
  appointmentRight: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  appointmentDate: {
    fontSize: '12px',
    color: '#666',
    fontWeight: '500',
  },
  statusBadge: {
    display: 'inline-block',
    padding: '4px 8px',
    borderRadius: '4px',
    fontSize: '11px',
    fontWeight: '600',
    marginTop: '6px',
  },
  statusUpcoming: {
    backgroundColor: '#d1fae5',
    color: '#065f46',
  },
  statusCancelled: {
    backgroundColor: '#fee2e2',
    color: '#991b1b',
  },
  plansList: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
    gap: '16px',
  },
  planCard: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '20px',
    border: '1px solid #f0f0f0',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.08)',
  },
  planHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '12px',
  },
  planName: {
    fontSize: '14px',
    color: '#111',
  },
  planDates: {
    fontSize: '12px',
    color: '#999',
  },
  planTitle: {
    fontSize: '14px',
    color: '#666',
    marginBottom: '12px',
  },
  planMeta: {
    display: 'flex',
    gap: '12px',
    fontSize: '12px',
    color: '#667eea',
    fontWeight: '500',
  },
  formsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
    gap: '24px',
  },
  formPanel: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '24px',
    border: '1px solid #f0f0f0',
    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.08)',
  },
  formHeader: {
    marginBottom: '24px',
    paddingBottom: '16px',
    borderBottom: '1px solid #e5e7eb',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '16px',
  },
  formGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  twoColumn: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '16px',
  },
  select: {
    padding: '10px 12px',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    fontSize: '14px',
    outline: 'none',
    transition: 'all 0.2s',
  },
  input: {
    padding: '10px 12px',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    fontSize: '14px',
    outline: 'none',
    transition: 'all 0.2s',
  },
  textarea: {
    padding: '10px 12px',
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    fontSize: '14px',
    fontFamily: 'inherit',
    outline: 'none',
    transition: 'all 0.2s',
    resize: 'vertical',
  },
  mealsGroup: {
    marginTop: '24px',
    paddingTop: '24px',
    borderTop: '1px solid #e5e7eb',
  },
  mealLabel: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#333',
    marginBottom: '8px',
    display: 'block',
  },
  submitButton: {
    padding: '12px',
    backgroundColor: '#667eea',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.2s',
    marginTop: '8px',
  },
};

export default App;
