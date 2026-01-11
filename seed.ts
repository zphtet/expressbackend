import { prisma } from './lib/prisma.js'

async function main() {
  console.log('🌱 Starting seed...')

  // Clear existing data (optional - comment out if you want to keep existing data)
  console.log('Clearing existing data...')
  await prisma.post.deleteMany()
  await prisma.user.deleteMany()
  await prisma.book.deleteMany()

  // Create 10 Users
  console.log('Creating 10 users...')
  const users = []
  for (let i = 1; i <= 10; i++) {
    const user = await prisma.user.create({
      data: {
        email: `user${i}@example.com`,
        name: `User ${i}`,
      },
    })
    users.push(user)
    console.log(`  ✓ Created user: ${user.email}`)
  }

  // Create 10 Posts (one for each user)
  console.log('Creating 10 posts...')
  for (let i = 0; i < 10; i++) {
    const post = await prisma.post.create({
      data: {
        title: `Post ${i + 1}: Sample Title`,
        content: `This is the content for post ${i + 1}. It contains some sample text for testing purposes.`,
        published: i % 2 === 0, // Alternate between published and unpublished
        authorId: users[i].id,
      },
    })
    console.log(`  ✓ Created post: ${post.title}`)
  }

  // Create 10 Books
  console.log('Creating 10 books...')
  const bookTitles = [
    'The Great Adventure',
    'Mystery of the Night',
    'Journey to the Stars',
    'Secrets of the Deep',
    'The Lost City',
    'Echoes of Time',
    'Whispers in the Wind',
    'The Hidden Truth',
    'Beyond the Horizon',
    'The Final Chapter',
  ]

  for (let i = 0; i < 10; i++) {
    const book = await prisma.book.create({
      data: {
        title: bookTitles[i],
        published: i < 5, // First 5 are published
      },
    })
    console.log(`  ✓ Created book: ${book.title}`)
  }

  console.log('✅ Seed completed successfully!')
  console.log(`   - ${users.length} users created`)
  console.log(`   - 10 posts created`)
  console.log(`   - 10 books created`)
}

main()
  .then(async () => {
    await prisma.$disconnect()
  })
  .catch(async (e) => {
    console.error('❌ Error during seeding:', e)
    await prisma.$disconnect()
    process.exit(1)
  })
