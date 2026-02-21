import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"

const formatTime = (date: Date) => {
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: true
  })
}

function Welcome() {
  const [currentTime, setCurrentTime] = useState(new Date())

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)

    return () => clearInterval(timer)
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 p-8">
      <div className="max-w-4xl mx-auto space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-5xl font-bold tracking-tight text-slate-900 dark:text-slate-50">
            {"Welcome to " + window.location.href}
          </h1>
          <p className="text-xl text-slate-600 dark:text-slate-400">
            Built with React, Vite, and shadcn/ui
          </p>
          <div className="text-3xl font-semibold text-red-600 mt-4">
            {formatTime(currentTime)}
          </div>
        </div>

        {/* Alert */}
        <Alert>
          <AlertTitle>Welcome!</AlertTitle>
          <AlertDescription>
            This is a demo page showcasing various shadcn/ui components. Explore the
            modern and accessible UI components below.
          </AlertDescription>
        </Alert>

        {/* Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Feature One</CardTitle>
              <CardDescription>
                Modern and responsive design with Tailwind CSS
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Build beautiful user interfaces with pre-styled components that are
                fully customizable and accessible out of the box.
              </p>
            </CardContent>
            <CardFooter>
              <Button>Learn More</Button>
            </CardFooter>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Feature Two</CardTitle>
              <CardDescription>
                Type-safe with TypeScript support
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Enjoy full TypeScript support with type definitions for all
                components, ensuring type safety throughout your application.
              </p>
            </CardContent>
            <CardFooter>
              <Button variant="secondary">Explore</Button>
            </CardFooter>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Feature Three</CardTitle>
              <CardDescription>
                Fast development with Vite
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                Experience lightning-fast hot module replacement and optimized builds
                with Vite's next-generation frontend tooling.
              </p>
            </CardContent>
            <CardFooter>
              <Button variant="outline">Get Started</Button>
            </CardFooter>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Feature Four</CardTitle>
              <CardDescription>
                Accessible and customizable
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                All components follow WAI-ARIA guidelines and can be easily
                customized to match your brand and design system.
              </p>
            </CardContent>
            <CardFooter className="gap-2">
              <Button variant="default">Primary</Button>
              <Button variant="ghost">Ghost</Button>
            </CardFooter>
          </Card>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-center gap-4">
          <Button size="lg">Get Started</Button>
          <Button size="lg" variant="outline">
            Documentation
          </Button>
        </div>
      </div>
    </div>
  )
}

export default Welcome
